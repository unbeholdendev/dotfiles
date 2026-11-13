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

sudo=; [[ $EUID == 0 ]] || sudo=sudo

if (( ${#missing[@]} )); then
  if   command -v apt-get >/dev/null; then
    $sudo apt-get update
    $sudo apt-get install -y "${missing[@]/#xz/xz-utils}"
  elif command -v dnf >/dev/null; then $sudo dnf install -y "${missing[@]}"
  elif command -v apk >/dev/null; then $sudo apk add "${missing[@]}"
  else echo "cannot install ${missing[*]}: no known package manager" >&2; exit 1
  fi
fi

# dcup sets T3_BROWSER when asked. It is a prebuilt Chrome: it cannot load
# libraries from the nix store.
# Agents work without it, so a failure here must not stop the install.
t64() {
  local policy
  policy=$(apt-cache policy "$1t64" 2>/dev/null) || true
  if [[ $policy == *Candidate:* && $policy != *"Candidate: (none)"* ]]; then echo "$1t64"; else echo "$1"; fi
}

loaded=$(PATH=$PATH:/sbin ldconfig -p 2>/dev/null) || true
browser_ready=$(fc-match --format='%{file}' sans-serif 2>/dev/null) || true
for lib in libnspr4.so libnss3.so libnssutil3.so libglib-2.0.so.0 libatk-1.0.so.0 \
  libatk-bridge-2.0.so.0 libatspi.so.0 libdbus-1.so.3 libX11.so.6 libxcb.so.1 \
  libXcomposite.so.1 libXdamage.so.1 libXext.so.6 libXfixes.so.3 libXrandr.so.2 \
  libxkbcommon.so.0 libgbm.so.1 libasound.so.2 libexpat.so.1; do
  [[ $loaded == *"$lib"* ]] || browser_ready=
done

if [[ -n ${T3_BROWSER:-} && -z $browser_ready ]]; then
  if command -v apt-get >/dev/null; then
    { $sudo apt-get update && $sudo apt-get install -y --no-install-recommends \
      libnss3 libdbus-1-3 libx11-6 libxcb1 libxcomposite1 libxdamage1 libxext6 \
      libxfixes3 libxrandr2 libxkbcommon0 libgbm1 libexpat1 fontconfig fonts-liberation \
      "$(t64 libglib2.0-0)" "$(t64 libatk1.0-0)" "$(t64 libatk-bridge2.0-0)" \
      "$(t64 libatspi2.0-0)" "$(t64 libasound2)"; } ||
      echo "T3's browser libraries did not install" >&2
  elif command -v dnf >/dev/null; then
    $sudo dnf install -y --setopt=install_weak_deps=False \
      nspr nss nss-util glib2 atk at-spi2-atk at-spi2-core dbus-libs \
      libX11 libxcb libXcomposite libXdamage libXext libXfixes libXrandr \
      libxkbcommon mesa-libgbm alsa-lib expat fontconfig dejavu-sans-fonts ||
      echo "T3's browser libraries did not install" >&2
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

PATH="$HOME/.nix-profile/bin:$PATH" ./agents/setup.sh "$repo"
