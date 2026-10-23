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
    echo "usage: ${0##*/} container [claude|pi]" >&2; exit 1 ;;
esac

# dcup passes the agent it asked for; later runs read it back from the file.
agent=${2:-}
[[ -z $agent && -f $HOME/.coding-agent ]] && agent=$(<"$HOME/.coding-agent")
if [[ -z $agent && -t 0 ]]; then
  PS3='which coding agent for this container? '
  select agent in claude pi; do [[ -n $agent ]] && break; done
fi
agent=${agent:-claude}
case $agent in
  claude|pi) ;;
  *) echo "usage: ${0##*/} container [claude|pi]" >&2; exit 1 ;;
esac
printf '%s\n' "$agent" > "$HOME/.coding-agent"
export CONTAINER_AGENT=$agent

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

if [[ $agent == claude ]]; then
  [[ -z ${CLAUDE_CONFIG_DIR:-} && -d /claude ]] && export CLAUDE_CONFIG_DIR=/claude
  cfg=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
  mkdir -p "$cfg"
  ln -sfn "$repo/claude/.claude/settings.json" "$cfg/settings.json"
  ln -sfn "$repo/agents/AGENTS.md" "$cfg/CLAUDE.md"
  mkdir -p "$cfg/skills"
  ln -sfn "$repo/agents/skills/natural-voice" "$cfg/skills/natural-voice"
else
  [[ -z ${PI_CODING_AGENT_DIR:-} && -d /pi ]] && export PI_CODING_AGENT_DIR=/pi
  piconf=${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}
  mkdir -p "$piconf/skills"
  ln -sfn "$repo/agents/AGENTS.md" "$piconf/AGENTS.md"
  ln -sfn "$repo/agents/skills/natural-voice" "$piconf/skills/natural-voice"
  ln -sfn "$repo/pi/.pi/agent/mcp.json" "$piconf/mcp.json"
  # Pi rewrites settings.json, so it is a copy made once, never a link into
  # the clone: lastChangelogVersion alone would dirty it for every container.
  [[ -f $piconf/settings.json ]] ||
    cp "$repo/pi/.pi/agent/settings.json" "$piconf/settings.json"
fi
