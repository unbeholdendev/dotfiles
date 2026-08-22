#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Re-exec after the pull so the pulled version of this file does the stow.
# Without it a package added upstream is never linked.
if [[ -z ${DOTS_PULLED:-} ]]; then
  git pull --rebase --autostash
  DOTS_PULLED=1 exec "$0"
fi

# The herdr folder must exist, or stow folds it into a link to this repo and the
# settings screen then writes config.toml here.
mkdir -p "$HOME/.config/herdr" "$HOME/.config/mise"
stow -R --target="$HOME" zsh nvim herdr mise
