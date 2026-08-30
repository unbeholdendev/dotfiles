#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# The dotfiles hook passes no argument, so a container has to name itself. A
# host does not reach this script at all: `dots` there is a program home-manager
# installs, holding the clone and the flake output it switches.
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

# A bare image has none of these and is not ours to change. zsh has to come
# from the distro because it is the login shell; the other three are what the
# nix installer needs to run at all.
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
  else echo "cannot install ${missing[*]}: no known package manager" >&2
  fi
fi

# A container has no nixbld group, and the installer stops rather than build
# without one. Flakes are off by default, and the build sandbox wants
# privileges a container is not given.
mkdir -p "$HOME/.config/nix"
cat > "$HOME/.config/nix/nix.conf" <<'EOF'
build-users-group =
experimental-features = nix-command flakes
sandbox = false
EOF

# `dcup` mounts /nix as one volume for every container, so the store is fetched
# once. A container started any other way has no such mount and installs into
# its own filesystem, which is what `mise.run` used to do here.
#
# --no-modify-profile because the installer otherwise appends a line naming
# /root to the first shell file it finds, and that file is this repo's.
if [[ ! -x /nix/var/nix/profiles/default/bin/nix ]]; then
  curl -fsSL https://nixos.org/nix/install | sh -s -- --no-daemon --no-modify-profile
fi
export PATH=/nix/var/nix/profiles/default/bin:$PATH

# The store is shared and nix locks it, but the profile must not be shared: a
# switch in one container would otherwise replace the tools of another that is
# still running. This one dies with the container.
mkdir -p "$HOME/.local/state/nix/profiles"
ln -sfn "$HOME/.local/state/nix/profiles/profile" "$HOME/.nix-profile"

# The output is a fixed name, since a container hostname is a random id, and
# the two facts that vary are read from here. `--impure` is for those alone.
export HOME_USER
HOME_USER=$(id -un)
out=$(nix build --no-link --print-out-paths --impure \
  "$PWD#homeConfigurations.container.activationPackage")
HOME_MANAGER_BACKUP_EXT=hm-bak "$out/activate"

# `.zshenv` reads this to find the clone, since resolving `~/.zshrc` says
# nothing where home-manager put that file in the store.
printf '%s\n' "$PWD" > "$HOME/.dots-path"

# home-manager writes under $HOME alone, and the config directory moves with a
# volume that is not under it, so this link is the script's and not a module's.
[[ -z ${CLAUDE_CONFIG_DIR:-} && -d /claude ]] && export CLAUDE_CONFIG_DIR=/claude
cfg=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
mkdir -p "$cfg"
ln -sfn "$PWD/claude/.claude/settings.json" "$cfg/settings.json"
