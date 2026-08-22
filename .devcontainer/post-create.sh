#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p "$HOME/.config" "$HOME/.config/mise"
stow -v --restow --target="$HOME" zsh nvim mise

# A mise shim falls through to the system binary when no version is selected, so
# a link that did not happen would give the wrong build and no error.
if [[ $(command -v nvim) != "$HOME/.local/share/mise/shims/"* ]]; then
  echo "nvim is not the mise build; the mise package did not link" >&2
  exit 1
fi

cat > "$CLAUDE_CONFIG_DIR/settings.json" <<'JSON'
{
  "permissions": { "defaultMode": "bypassPermissions" },
  "skipDangerousModePermissionPrompt": true,
  "theme": "dark"
}
JSON

echo "post-create done: stowed dotfiles into $HOME as $(whoami)"
