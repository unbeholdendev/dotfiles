#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
stow -v zsh
echo "post-create done: dotfiles stowed for $(whoami)"
