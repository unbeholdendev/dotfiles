typeset -U path PATH

[[ -z ${DOTFILES:-} && -r ~/.dots-path ]] && export DOTFILES=$(<~/.dots-path)

[[ -z ${CLAUDE_CONFIG_DIR:-} && -d /claude ]] && export CLAUDE_CONFIG_DIR=/claude

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
