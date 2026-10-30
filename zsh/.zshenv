typeset -U path PATH

[[ -z ${DOTFILES:-} && -r ~/.dots-path ]] && export DOTFILES=$(<~/.dots-path)

[[ -z ${CODEX_HOME:-} && -d /codex ]] && export CODEX_HOME=/codex
[[ -z ${CLAUDE_CONFIG_DIR:-} && -d /claude ]] && export CLAUDE_CONFIG_DIR=/claude
[[ -z ${PI_CODING_AGENT_DIR:-} && -d /pi ]] && export PI_CODING_AGENT_DIR=/pi
[[ -z ${PI_CODING_AGENT_SESSION_DIR:-} && -d /history ]] && export PI_CODING_AGENT_SESSION_DIR=/history/pi/sessions

# Claude Code exits rather than run as root without this.
[[ -f /.dockerenv || -f /run/.containerenv ]] && export IS_SANDBOX=1

path=(~/.local/bin ~/.devcontainers/bin $path)

# A niri session and `devcontainer exec` read none of the installer's own files.
if [[ -d ~/.nix-profile/bin ]]; then
  path=(~/.nix-profile/bin $path)
  export XDG_DATA_DIRS=~/.nix-profile/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}
  [[ -r ~/.nix-profile/etc/profile.d/hm-session-vars.sh ]] &&
    source ~/.nix-profile/etc/profile.d/hm-session-vars.sh
fi
