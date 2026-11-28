#!/usr/bin/env bash
set -euo pipefail

repo=$1

for agent in claude codex; do
  sources=(
    cursor/plugins:6b0300214a09fd6029cfb7077043125758cd1fd2
    cloudflare/security-audit-skill:c1c8a8c1471069fb0e188eeaff69b8e8db6564a8
    mattpocock/skills:5beb35b040e3de97e54fa9e386d7e42d15c295c2
    pbakaus/impeccable:33003f1013a636e612752a1cad7b82b8bb4c67f2
  )

  if [[ $agent == claude ]]; then
    cfg=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
    mkdir -p "$cfg"
    ln -sfn "$repo/claude/.claude/settings.json" "$cfg/settings.json"
    ln -sfn "$repo/agents/AGENTS.md" "$cfg/CLAUDE.md"
  else
    cfg=${CODEX_HOME:-$HOME/.codex}
    mkdir -p "$cfg"
    ln -sfn "$repo/agents/AGENTS.md" "$cfg/AGENTS.md"
    [[ -f $cfg/config.toml ]] || cp "$repo/codex/.codex/config.toml" "$cfg/config.toml"
    [[ ! -L $cfg/hooks.json ]] || rm "$cfg/hooks.json"
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

  rm -f "$cfg/skills/mattpocock-engineering" "$cfg/skills/mattpocock-productivity"
  for skill in "$cfg"/third-party/mattpocock/skills/{engineering,productivity}/*/; do
    skill=${skill%/}
    ln -sfn "$skill" "$cfg/skills/${skill##*/}"
  done
  impeccable=.agents
  [[ $agent == codex ]] || impeccable=.claude
  ln -sfn "$cfg/third-party/pbakaus/$impeccable/skills/impeccable" "$cfg/skills/impeccable"
done
