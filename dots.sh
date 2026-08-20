#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Re-exec after the pull so the pulled version of this file does the stow.
# Without it a package added upstream is never linked.
if [[ -z ${DOTS_PULLED:-} ]]; then
  git pull --rebase --autostash
  DOTS_PULLED=1 exec "$0"
fi

# The noctalia state folder must exist, or stow folds it into a link to this
# repo and the shell then writes state.toml and its caches here.
mkdir -p "$HOME/.config" "$HOME/.ssh" "$HOME/.local/state/noctalia"
stow -R --target="$HOME" zsh ssh niri nvim foot portal wireplumber yazi noctalia

# color-scheme drives the settings portal; GTK3 does not read it, so it needs gtk-theme.
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
