#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Re-exec after the pull so the pulled version of this file does the stow.
# Without it a package added upstream is never linked.
if [[ -z ${DOTS_PULLED:-} ]]; then
  git pull --rebase --autostash
  DOTS_PULLED=1 exec "$0"
fi

mkdir -p "$HOME/.config" "$HOME/.ssh"
stow -R --target="$HOME" zsh ssh niri nvim foot portal wireplumber yazi

# color-scheme drives the settings portal; GTK3 does not read it, so it needs gtk-theme.
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
