typeset -U path PATH

# The mount is the signal rather than an env var, because an external project's
# devcontainer.json is not ours to edit.
[[ -z ${MISE_DATA_DIR:-} && -d /mise ]] && export MISE_DATA_DIR=/mise
[[ -z ${CLAUDE_CONFIG_DIR:-} && -d /claude ]] && export CLAUDE_CONFIG_DIR=/claude

# Claude Code exits rather than run as root without this, and the stowed
# settings.json asks for bypassPermissions in every container it reaches.
[[ -f /.dockerenv || -f /run/.containerenv ]] && export IS_SANDBOX=1

path=(${MISE_DATA_DIR:-~/.local/share/mise}/shims ~/.local/bin ~/.devcontainers/bin $path)
