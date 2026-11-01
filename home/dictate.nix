{ pkgs, ... }:
let
  prompt = "niri, noctalia, nixpkgs, NixOS, home-manager, disko, Forgejo, Claude, yazi, foot, zsh.";

  dictate = pkgs.writeShellApplication {
    name = "dictate";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      ffmpeg
      libnotify
      wl-clipboard
      wtype
    ];
    text = ''
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

      terms=$(cat "$HOME/.dictate-terms" 2>/dev/null || true)

      text=$(curl -sS --fail-with-body \
        https://api.groq.com/openai/v1/audio/transcriptions \
        -H "Authorization: Bearer $(cat "$HOME/.groq-token")" \
        -F model=whisper-large-v3-turbo \
        -F response_format=text \
        -F language=en \
        --form-string prompt=${pkgs.lib.escapeShellArg prompt}" $terms" \
        -F file=@"$clip" | tee "$log") || text=

      rm -f "$clip"

      if [ -z "$text" ]; then
        notify-send -u critical "Dictation failed" "$log" || true
        exit 1
      fi

      printf '%s' "$text" | wl-copy
      printf '%s' "$text" | wtype -
      notify-send -t 2000 "Dictated" "$text" || true
    '';
  };
in
{
  home.packages = [ dictate ];
}
