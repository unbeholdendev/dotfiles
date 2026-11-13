#!/usr/bin/env bash
set -euo pipefail

repo=$1

trust_codex_hooks() {
  local reply state
  coproc APP { timeout 30 codex app-server 2>/dev/null; }
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
    cursor/plugins:6b0300214a09fd6029cfb7077043125758cd1fd2
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
    CODEX_HOME=$cfg trust_codex_hooks "$cfg/hooks.json" ||
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
  [[ ! -L $cfg/skills/no-ai-slop ]] || rm "$cfg/skills/no-ai-slop"
  mkdir -p "$cfg/skills/unslop"
  sed '/^disable-model-invocation: true$/d' \
    "$cfg/third-party/cursor/pstack/skills/unslop/SKILL.md" > "$cfg/skills/unslop/SKILL.md"
  ln -sfn "$cfg/third-party/cloudflare/skills/security-audit" "$cfg/skills/security-audit"

  if [[ $agent == codex ]]; then
    ln -sfn "$cfg/third-party/mattpocock/skills/engineering" "$cfg/skills/mattpocock-engineering"
    ln -sfn "$cfg/third-party/mattpocock/skills/productivity" "$cfg/skills/mattpocock-productivity"
    ln -sfn "$cfg/third-party/pbakaus/.agents/skills/impeccable" "$cfg/skills/impeccable"
  fi
done
