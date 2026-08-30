#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# A container sees this clone twice, as the workspace and as the /dotfiles
# mount. stow owns the links under one name, so hand the run to that one.
if [[ -d /dotfiles && $(stat -c '%d:%i' .) == $(stat -c '%d:%i' /dotfiles) \
      && $PWD != /dotfiles ]]; then
  exec /dotfiles/install.sh "$@"
fi

# The dotfiles hook passes no argument, so a container has to name itself. A
# host does not reach this script at all: `dots` there is a program home-manager
# installs, holding the clone and the flake output it switches.
profile=${1:-}
if [[ -z $profile ]]; then
  [[ -f /.dockerenv || -f /run/.containerenv ]] && profile=container
fi

case $profile in
  container)
    packages=(zsh nvim mise claude) ;;
  desktop|server)
    echo "$profile is a home-manager host: run dots" >&2; exit 1 ;;
  *)
    echo "usage: ${0##*/} container" >&2; exit 1 ;;
esac

# A bare image has none of these and is not ours to change. A failure is not
# fatal: stow below reports itself missing, and `.zshrc` skips a plugin it
# cannot read.
missing=()
command -v git  >/dev/null || missing+=(git)
command -v zsh  >/dev/null || missing+=(zsh)
command -v stow >/dev/null || missing+=(stow)
[[ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] \
  || missing+=(zsh-autosuggestions)
[[ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] \
  || missing+=(zsh-syntax-highlighting)

if (( ${#missing[@]} )); then
  sudo=; [[ $EUID == 0 ]] || sudo=sudo
  if   command -v apt-get >/dev/null; then $sudo apt-get update && $sudo apt-get install -y "${missing[@]}"
  elif command -v dnf     >/dev/null; then $sudo dnf install -y "${missing[@]}"
  elif command -v apk     >/dev/null; then $sudo apk add "${missing[@]}"
  else echo "cannot install ${missing[*]}: no known package manager" >&2
  fi
fi

# --no-folding keeps each folder real. Without it stow replaces a folder holding
# one package's files with a link to this repo, and tools then write in here.
# Every stow call needs the flag, `-D` included. `-d` takes the directory
# absolutely: given a relative one, stow walks $HOME, meets a link into /nix,
# and dies comparing an absolute path with a relative stow directory.
stow -R --no-folding -d "$PWD" --target="$HOME" "${packages[@]}"

# `.zshenv` reads this to find the clone, since resolving `~/.zshrc` says
# nothing on a host, where home-manager puts that file in the store.
printf '%s\n' "$PWD" > "$HOME/.dots-path"

[[ -z ${CLAUDE_CONFIG_DIR:-} && -d /claude ]] && export CLAUDE_CONFIG_DIR=/claude
cfg=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
mkdir -p "$cfg"
ln -sfn "$PWD/claude/.claude/settings.json" "$cfg/settings.json"

[[ -z ${MISE_DATA_DIR:-} && -d /mise ]] && export MISE_DATA_DIR=/mise
shims=${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims
PATH="$shims:$HOME/.local/bin:$PATH"
command -v mise >/dev/null || curl -fsSL https://mise.run | sh
mise install

# A mise shim falls through to the system binary when no version is selected,
# so a link that did not happen would give the wrong build and no error.
if [[ $(command -v nvim) != "$shims/"* ]]; then
  echo "nvim is not the mise build; the mise package did not link" >&2
  exit 1
fi
