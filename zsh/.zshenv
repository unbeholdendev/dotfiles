typeset -U path PATH

# The clone cannot be found by resolving this file any more: home-manager puts
# it in the store. Whoever placed it names it here instead.
[[ -z ${DOTFILES:-} && -r ~/.dots-path ]] && export DOTFILES=$(<~/.dots-path)

# The mount is the signal rather than an env var, because an external project's
# devcontainer.json is not ours to edit.
[[ -z ${CLAUDE_CONFIG_DIR:-} && -d /claude ]] && export CLAUDE_CONFIG_DIR=/claude

# Claude Code exits rather than run as root without this, and the settings.json
# install.sh links asks for bypassPermissions in every container it reaches.
[[ -f /.dockerenv || -f /run/.containerenv ]] && export IS_SANDBOX=1

path=(~/.local/bin ~/.devcontainers/bin $path)

# The nix installer writes its profile into the files a login or an interactive
# shell reads. A niri session is neither, and neither is `devcontainer exec`,
# so the one file every zsh reads is where this belongs. It is last so a pinned
# tool wins over one dropped in ~/.local/bin by hand, and XDG_DATA_DIRS goes
# with it, or a launcher sees no app nix installs.
if [[ -d ~/.nix-profile/bin ]]; then
  path=(~/.nix-profile/bin $path)
  export XDG_DATA_DIRS=~/.nix-profile/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}
fi
