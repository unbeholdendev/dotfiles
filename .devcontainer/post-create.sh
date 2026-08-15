#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p "$HOME/.config"
stow -v --restow --target="$HOME" zsh nvim foot

cat > "$CLAUDE_CONFIG_DIR/settings.json" <<'JSON'
{
  "permissions": { "defaultMode": "bypassPermissions" },
  "skipDangerousModePermissionPrompt": true,
  "theme": "dark"
}
JSON

echo "post-create done: stowed dotfiles into $HOME as $(whoami)"
