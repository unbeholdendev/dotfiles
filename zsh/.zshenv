typeset -U path PATH

# A dev container gets the mise store as a shared volume at /mise, so one
# download serves every container. The mount is the signal rather than an env
# var, because an external project's devcontainer.json is not ours to edit.
[[ -z ${MISE_DATA_DIR:-} && -d /mise ]] && export MISE_DATA_DIR=/mise
[[ -z ${CLAUDE_CONFIG_DIR:-} && -d /claude ]] && export CLAUDE_CONFIG_DIR=/claude
path=(${MISE_DATA_DIR:-~/.local/share/mise}/shims ~/.local/bin ~/.devcontainers/bin $path)
