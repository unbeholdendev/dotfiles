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

trust_codex_hooks() {
  local reply state
  coproc APP { timeout 30 "$HOME/.nix-profile/bin/codex" app-server 2>/dev/null; }
  send() { printf '%s\n' "$1" >&"${APP[1]}"; }
  await() {
    while read -r reply <&"${APP[0]}"; do
      [[ $(jq -c .id <<<"$reply") == "$1" ]] && return
    done
    return 1
  }
  send '{"id":1,"method":"initialize","params":{"clientInfo":{"name":"install","version":"0"}}}'
  await 1 || return 1
  send '{"method":"initialized"}'
  send "$(jq -nc --arg cwd "$PWD" '{id:2,method:"hooks/list",params:{cwds:[$cwd]}}')"
  await 2 || return 1
  state=$(jq -c --arg source "$1" '[.result.data[].hooks[] | select(.sourcePath == $source)
    | {key, value: {trusted_hash: .currentHash}}] | from_entries' <<<"$reply")
  [[ $state != '{}' ]] || return 1
  send "$(jq -nc --argjson state "$state" \
    '{id:3,method:"config/value/write",params:{keyPath:"hooks.state",value:$state,mergeStrategy:"upsert"}}')"
  await 3 || return 1
  kill "$APP_PID" 2>/dev/null || true
  jq -e .result >/dev/null <<<"$reply"
}

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
    ln -sfn "$repo/codex/.codex/hooks.json" "$cfg/hooks.json"
    # Codex skips a hook nobody has trusted, and no one is there to answer its prompt.
    PATH="$HOME/.nix-profile/bin:$PATH" CODEX_HOME=$cfg trust_codex_hooks "$cfg/hooks.json" ||
      echo "Codex PR merge hook not trusted: approve it with /hooks" >&2
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
