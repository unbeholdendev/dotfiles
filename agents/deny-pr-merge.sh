input=$(cat)
command=$(jq -r '.tool_input.command // ""
  | gsub("<<-?[ \t]*[\"'"'"']?(?<tag>\\w+)[\"'"'"']?(?<rest>[^\n]*)\n.*?\n[ \t]*\\k<tag>(?=\n|$)"; "\(.rest)"; "p")
  | gsub("(?<text>\"(?:\\\\.|[^\"\\\\])*\"|'"'"'[^'"'"']*'"'"')"; .text | gsub(if startswith("\"") then "[;&|\n]|(?<!\\$)\\(" else "[;&|(\n]" end; " "))' <<<"$input")
cwd=$(jq -r '.cwd // empty' <<<"$input")
cwd=${cwd:-$PWD}

deny() {
  echo "$1" >&2
  exit 2
}

start='(^|[;&|(])[[:space:]]*'
if grep -qE "${start}(tea|gh)[[:space:]]+(pr|pulls?)[[:space:]]+(merge|m)([[:space:]]|$)|pulls/[^/[:space:]]+/merge|repos/[^/[:space:]]+/[^/[:space:]]+/merges([^[:alnum:]_-]|$)" <<<"$command"; then
  deny "Never merge a PR; the user merges."
fi

protected() {
  local dir=$1 branch=$2 default
  default=$(git -C "$dir" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)
  [[ $branch == main || $branch == master || ($default && $branch == "${default#origin/}") ]]
}

check_push() {
  local dir=$cwd args=() remote=1 refspecs ref dst branch
  while true; do
    (($#)) || return 0
    case $1 in
      -C) [[ $2 == /* ]] && dir=$2 || dir=$dir/$2; shift 2 ;;
      -c | --git-dir | --work-tree | --namespace) shift 2 ;;
      -*) shift ;;
      push) shift; break ;;
      *) return 0 ;;
    esac
  done
  while (($#)); do
    case $1 in
      --all | --mirror | --branches) deny "Never push every branch; push your own branch and open a PR." ;;
      --repo) remote=0; shift 2 ;;
      --repo=*) remote=0; shift ;;
      -o | --push-option | --receive-pack | --exec) shift 2 ;;
      -*) shift ;;
      *) args+=("$1"); shift ;;
    esac
  done
  refspecs=("${args[@]:remote}")
  branch=$(git -C "$dir" symbolic-ref --quiet --short HEAD 2>/dev/null || true)
  ((${#refspecs[@]})) || refspecs=("$branch")
  for ref in "${refspecs[@]}"; do
    ref=${ref#+}
    dst=$ref
    [[ $ref == *:* ]] && dst=${ref#*:}
    [[ $ref == : ]] && deny "Never push matching branches; push your own branch and open a PR."
    dst=${dst#refs/heads/}
    [[ $dst == HEAD || $dst == @ ]] && dst=$branch
    if [[ $dst ]] && protected "$dir" "$dst"; then
      deny "Never push to $dst; push a branch and open a PR."
    fi
  done
}

while IFS= read -r segment; do
  read -r -a words <<<"$segment"
  words=("${words[@]//[\"\']/}")
  for i in "${!words[@]}"; do
    case ${words[i]} in
      *=* | env | command | exec | nohup | time) ;;
      git | */git) check_push "${words[@]:i+1}"; break ;;
      *) break ;;
    esac
  done
done < <(tr ';&|()`' '\n' <<<"$command")
