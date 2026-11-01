command=$(jq -r '.tool_input.command // ""
  | gsub("<<-?[ \t]*[\"'"'"']?(?<tag>\\w+)[\"'"'"']?(?<rest>[^\n]*)\n.*?\n[ \t]*\\k<tag>(?=\n|$)"; "\(.rest)"; "p")
  | gsub("(?<text>\"(?:\\\\.|[^\"\\\\])*\"|'"'"'[^'"'"']*'"'"')"; .text | gsub(if startswith("\"") then "[;&|\n]|(?<!\\$)\\(" else "[;&|(\n]" end; " "))')
start='(^|[;&|(])[[:space:]]*'
if grep -qE "${start}tea[[:space:]]+(pr|pulls?)[[:space:]]+(merge|m)([[:space:]]|$)|${start}tea[[:space:]]+api[[:space:]][^;&|]*pulls/[^/[:space:]]+/merge" <<<"$command"; then
  echo "Never merge a PR; the user merges." >&2
  exit 2
fi
