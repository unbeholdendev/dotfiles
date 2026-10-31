#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

profile=${1:-}
if [[ -z $profile ]]; then
  [[ -f /.dockerenv || -f /run/.containerenv ]] && profile=container
fi

case $profile in
  container) ;;
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

repo=$(git rev-parse --path-format=absolute --git-common-dir)
repo=${repo%/.git}
# /claude is one volume in every container, and /dotfiles is the one clone path they all share.
[[ -e /dotfiles/agents/AGENTS.md ]] && repo=/dotfiles
printf '%s\n' "$repo" > "$HOME/.dots-path"

for agent in claude codex; do
  sources=(
    petergyang/no-ai-slop:000650b156983f5159695b441477f4e63b25dc85
    cloudflare/security-audit-skill:c1c8a8c1471069fb0e188eeaff69b8e8db6564a8
  )

  if [[ $agent == claude ]]; then
    [[ -z ${CLAUDE_CONFIG_DIR:-} && -d /claude ]] && export CLAUDE_CONFIG_DIR=/claude
    cfg=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
    mkdir -p "$cfg"
    ln -sfn "$repo/claude/.claude/settings.json" "$cfg/settings.json"
    ln -sfn "$repo/agents/AGENTS.md" "$cfg/CLAUDE.md"
  else
    [[ -z ${CODEX_HOME:-} && -d /codex ]] && export CODEX_HOME=/codex
    cfg=${CODEX_HOME:-$HOME/.codex}
    mkdir -p "$cfg"
    ln -sfn "$repo/agents/AGENTS.md" "$cfg/AGENTS.md"
    [[ -f $cfg/config.toml ]] || cp "$repo/codex/.codex/config.toml" "$cfg/config.toml"
    sources+=(
      mattpocock/skills:5beb35b040e3de97e54fa9e386d7e42d15c295c2
      pbakaus/impeccable:33003f1013a636e612752a1cad7b82b8bb4c67f2
    )
  fi

  mkdir -p "$cfg/skills"

  for source in "${sources[@]}"; do
    upstream=${source%:*}
    revision=${source#*:}
    checkout=$cfg/third-party/${upstream%/*}
    [[ -d $checkout/.git ]] || git init -q "$checkout"
    if [[ $(git -C "$checkout" rev-parse HEAD 2>/dev/null || true) != "$revision" ]]; then
      git -C "$checkout" fetch --depth=1 "https://github.com/$upstream.git" "$revision"
      git -C "$checkout" checkout -q --detach "$revision"
    fi
  done
  ln -sfn "$cfg/third-party/petergyang/skills/no-ai-slop" "$cfg/skills/no-ai-slop"
  ln -sfn "$cfg/third-party/cloudflare/skills/security-audit" "$cfg/skills/security-audit"

  if [[ $agent == codex ]]; then
    ln -sfn "$cfg/third-party/mattpocock/skills/engineering" "$cfg/skills/mattpocock-engineering"
    ln -sfn "$cfg/third-party/mattpocock/skills/productivity" "$cfg/skills/mattpocock-productivity"
    ln -sfn "$cfg/third-party/pbakaus/.agents/skills/impeccable" "$cfg/skills/impeccable"
  fi
done
