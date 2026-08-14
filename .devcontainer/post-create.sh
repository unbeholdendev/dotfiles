#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

stow -v --restow --target="$HOME" zsh
echo "post-create done: stowed dotfiles into $HOME as $(whoami)"
