#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# A container sees this clone twice, as the workspace and as the /dotfiles
# mount. stow owns the links under one name, so hand the run to that one.
if [[ -d /dotfiles && $(stat -c '%d:%i' .) == $(stat -c '%d:%i' /dotfiles) \
      && $PWD != /dotfiles ]]; then
  exec /dotfiles/install.sh "$@"
fi

# Remember the profile per machine, so a bare `dots` on the agent host does not
# stow the desktop set and link ssh/ onto a host that cannot use it. A fresh
# container has no marker and the dotfiles hook passes no argument, so the
# fallback there must not be desktop either.
marker=$HOME/.dots-profile
default=desktop
[[ -f /.dockerenv || -f /run/.containerenv ]] && default=container
profile=${1:-$(cat "$marker" 2>/dev/null || echo "$default")}

# Every difference between the environments this repo serves is in this table.
case $profile in
  desktop)
    packages=(zsh ssh nvim)
    pull=1 mise_tools=0 desktop_theme=1 ;;
  server)
    packages=(zsh nvim herdr dcup mise)
    pull=1 mise_tools=1 desktop_theme=0 ;;
  container)
    packages=(zsh nvim mise claude)
    pull=0 mise_tools=1 desktop_theme=0 ;;
  *)
    echo "usage: ${0##*/} [desktop|server|container]" >&2; exit 1 ;;
esac

printf '%s\n' "$profile" > "$marker"

# Re-exec after the pull so the pulled version of this file does the stow.
# The container profile skips it: that clone is somebody's working tree.
if [[ $pull == 1 && -z ${DOTS_PULLED:-} ]]; then
  git pull --rebase --autostash
  DOTS_PULLED=1 exec "$0" "$profile"
fi

# A bare image has none of these and is not ours to change. A failure is not
# fatal: stow below reports itself missing, and `.zshrc` skips a plugin it
# cannot read.
missing=()
command -v git  >/dev/null || missing+=(git)
command -v zsh  >/dev/null || missing+=(zsh)
command -v stow >/dev/null || missing+=(stow)
[[ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] \
  || missing+=(zsh-autosuggestions)
[[ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] \
  || missing+=(zsh-syntax-highlighting)

if (( ${#missing[@]} )); then
  sudo=; [[ $EUID == 0 ]] || sudo=sudo
  if   command -v apt-get >/dev/null; then $sudo apt-get update && $sudo apt-get install -y "${missing[@]}"
  elif command -v dnf     >/dev/null; then $sudo dnf install -y "${missing[@]}"
  elif command -v apk     >/dev/null; then $sudo apk add "${missing[@]}"
  else echo "cannot install ${missing[*]}: no known package manager" >&2
  fi
fi

# --no-folding keeps each folder real. Without it stow replaces a folder holding
# one package's files with a link to this repo, and tools then write in here.
# Every stow call needs the flag, `-D` included.
stow -R --no-folding --target="$HOME" "${packages[@]}"

if [[ " ${packages[*]} " == *" claude "* ]]; then
  [[ -z ${CLAUDE_CONFIG_DIR:-} && -d /claude ]] && export CLAUDE_CONFIG_DIR=/claude
  cfg=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
  mkdir -p "$cfg"
  ln -sfn "$PWD/claude/.claude/settings.json" "$cfg/settings.json"
fi

if [[ $mise_tools == 1 ]]; then
  [[ -z ${MISE_DATA_DIR:-} && -d /mise ]] && export MISE_DATA_DIR=/mise
  shims=${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims
  PATH="$shims:$HOME/.local/bin:$PATH"
  command -v mise >/dev/null || curl -fsSL https://mise.run | sh
  mise install

  # A mise shim falls through to the system binary when no version is selected,
  # so a link that did not happen would give the wrong build and no error.
  if [[ $(command -v nvim) != "$shims/"* ]]; then
    echo "nvim is not the mise build; the mise package did not link" >&2
    exit 1
  fi
fi

if [[ $desktop_theme == 1 ]]; then
  # color-scheme drives the settings portal; GTK3 does not read it, so it also
  # needs gtk-theme.
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
  gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
fi
