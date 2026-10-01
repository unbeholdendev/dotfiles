{ pkgs, ... }:
let
  prompt = ''
    Transcribe this dictation. Fix punctuation, capitalisation and false
    starts, and use British English. Do not paraphrase, summarise, answer or
    add anything. Words that may appear: niri, noctalia, nixpkgs, NixOS,
    home-manager, disko, forgejo, yazi, foot, zsh.
    Return only the corrected text.
  '';

  dictate = pkgs.writeShellApplication {
    name = "dictate";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      ffmpeg
      jq
      libnotify
      wl-clipboard
    ];
    text = ''
      prompt=${pkgs.lib.escapeShellArg prompt}
      clip="$XDG_RUNTIME_DIR/dictate.wav"
      pidfile="$XDG_RUNTIME_DIR/dictate.pid"
      log="$XDG_RUNTIME_DIR/dictate.log"

      pid=$(cat "$pidfile" 2>/dev/null || true)
      rm -f "$pidfile"
      if [ -n "$pid" ] && kill -INT "$pid" 2>/dev/null; then
        while kill -0 "$pid" 2>/dev/null; do sleep 0.05; done
      else
        notify-send -t 1000 "Dictating" || true
        ffmpeg -nostdin -loglevel error -y \
          -f pulse -i default -ac 1 -ar 16000 "$clip" &
        echo $! > "$pidfile"
        exit 0
      fi

      payload=$(jq -n \
        --arg prompt "$prompt" \
        --arg audio "$(base64 -w0 "$clip")" \
        '{model: "gemini-3.8-flash", input: [
           {type: "text", text: $prompt},
           {type: "audio", data: $audio, mime_type: "audio/wav"}
         ]}')

      text=$(curl -sS --fail-with-body -X POST \
        https://generativelanguage.googleapis.com/v1beta/interactions \
        -H "x-goog-api-key: $(cat "$HOME/.gemini-token")" \
        -H 'Content-Type: application/json' \
        -d "$payload" | tee "$log" |
        jq -r --arg prompt "$prompt" \
          '[.. | objects | .text? | strings] - [$prompt] | first // empty' \
        || true)

      rm -f "$clip"

      if [ -z "$text" ]; then
        notify-send -u critical "Dictation failed" "$log" || true
        exit 1
      fi

      printf '%s' "$text" | wl-copy
      notify-send -t 2000 "Dictated" "$text" || true
    '';
  };
in
{
  home.packages = [ dictate ];
}
