#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

./install.sh container

# Not a stowed file: the identity is right here and wrong in a project shared
# with other people, and the helper must not answer for anyone else's forge.
git config --global user.name agent
git config --global user.email 335420059+unbeholdendev@users.noreply.github.com
git config --global credential."$FORGEJO_URL".helper \
  '!f() { echo username=agent; echo "password=$(cat "$HOME/.forgejo-token")"; }; f'

echo "post-create done: stowed dotfiles into $HOME as $(whoami)"
