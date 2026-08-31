#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

profile=${1:-}
if [[ -z $profile ]]; then
  [[ -f /.dockerenv || -f /run/.containerenv ]] && profile=container
fi

case $profile in
  container) ;;
  desktop|server)
    echo "$profile is a home-manager host: run dots" >&2; exit 1 ;;
  *)
    echo "usage: ${0##*/} container" >&2; exit 1 ;;
esac

# zsh is the login shell; the rest is what the nix installer needs to run.
missing=()
command -v git  >/dev/null || missing+=(git)
command -v zsh  >/dev/null || missing+=(zsh)
command -v curl >/dev/null || missing+=(curl)
command -v xz   >/dev/null || missing+=(xz)

if (( ${#missing[@]} )); then
  sudo=; [[ $EUID == 0 ]] || sudo=sudo
  if   command -v apt-get >/dev/null; then
    $sudo apt-get update
    $sudo apt-get install -y "${missing[@]/#xz/xz-utils}"
  elif command -v dnf >/dev/null; then $sudo dnf install -y "${missing[@]}"
  elif command -v apk >/dev/null; then $sudo apk add "${missing[@]}"
  else echo "cannot install ${missing[*]}: no known package manager" >&2; exit 1
  fi
fi

# A container has no nixbld group, and no privileges for the sandbox.
mkdir -p "$HOME/.config/nix"
cat > "$HOME/.config/nix/nix.conf" <<'EOF'
build-users-group =
experimental-features = nix-command flakes
sandbox = false
EOF

# No systemd for a daemon, and --no-modify-profile keeps /root out of our files.
if [[ ! -x /nix/var/nix/profiles/default/bin/nix ]]; then
  curl -fsSL https://nixos.org/nix/install | sh -s -- --no-daemon --no-modify-profile
fi
export PATH=/nix/var/nix/profiles/default/bin:$PATH

# A shared profile would let one container's switch replace another's tools.
mkdir -p "$HOME/.local/state/nix/profiles"
ln -sfn "$HOME/.local/state/nix/profiles/profile" "$HOME/.nix-profile"

export HOME_USER
HOME_USER=$(id -un)
out=$(nix build --no-link --print-out-paths --impure \
  "$PWD#homeConfigurations.container.activationPackage")
HOME_MANAGER_BACKUP_EXT=hm-bak "$out/activate"

printf '%s\n' "$PWD" > "$HOME/.dots-path"

[[ -z ${CLAUDE_CONFIG_DIR:-} && -d /claude ]] && export CLAUDE_CONFIG_DIR=/claude
cfg=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
mkdir -p "$cfg"
ln -sfn "$PWD/claude/.claude/settings.json" "$cfg/settings.json"
ln -sfn "$PWD/claude/.claude/CLAUDE.md" "$cfg/CLAUDE.md"
