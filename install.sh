#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Remember the profile per machine, so a bare `dots` on the agent host does not
# fall back to the desktop set and link ssh/ onto a host that cannot use it.
# The dev container dotfiles hook runs this file with no argument, and a fresh
# container has no marker, so the last resort must not be desktop there either.
marker=$HOME/.dots-profile
default=desktop
[[ -f /.dockerenv || -f /run/.containerenv ]] && default=container
profile=${1:-$(cat "$marker" 2>/dev/null || echo "$default")}

# Every difference between the environments this repo serves is in this table.
case $profile in
  desktop)
    packages=(zsh ssh niri nvim foot portal wireplumber yazi noctalia mise)
    pull=1 mise_tools=0 desktop_theme=1 ;;
  server)
    packages=(zsh nvim herdr mise)
    pull=1 mise_tools=1 desktop_theme=0 ;;
  container)
    packages=(zsh nvim mise)
    pull=0 mise_tools=1 desktop_theme=0 ;;
  *)
    echo "usage: ${0##*/} [desktop|server|container]" >&2; exit 1 ;;
esac

printf '%s\n' "$profile" > "$marker"

# Re-exec after the pull so the pulled version of this file does the stow.
# Without it a package added upstream is never linked. The container profile
# skips it, because its clone is fresh and it must not touch a working tree.
if [[ $pull == 1 && -z ${DOTS_PULLED:-} ]]; then
  git pull --rebase --autostash
  DOTS_PULLED=1 exec "$0" "$profile"
fi

# The standard dev container base images do not carry stow, and an external
# project's image is not ours to change, so install it here instead.
if ! command -v stow >/dev/null; then
  sudo=; [[ $EUID == 0 ]] || sudo=sudo
  if   command -v apt-get >/dev/null; then $sudo apt-get update && $sudo apt-get install -y stow
  elif command -v dnf     >/dev/null; then $sudo dnf install -y stow
  elif command -v apk     >/dev/null; then $sudo apk add stow
  else echo "stow is missing and no known package manager is present" >&2; exit 1
  fi
fi

# --no-folding keeps each folder real. Without it stow replaces a folder that
# holds only one package's files with a link to this repo, and the tool then
# writes its state here. Every stow call needs the flag, `-D` included, because
# removing a package folds the folder it leaves behind.
stow -R --no-folding --target="$HOME" "${packages[@]}"

if [[ $mise_tools == 1 ]]; then
  PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"
  command -v mise >/dev/null || curl -fsSL https://mise.run | sh
  mise install

  # A mise shim falls through to the system binary when no version is selected,
  # so a link that did not happen would give the wrong build and no error.
  if [[ $(command -v nvim) != "$HOME/.local/share/mise/shims/"* ]]; then
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
