# dotfiles

Config for a Fedora + niri machine. Authored in this dev container, then pulled
onto the real machine. The container is for editing, not the target.

Each top-level directory is a stow package whose interior mirrors `$HOME`:
`zsh/`, `ssh/`, `niri/`, `nvim/`. Adding a package means adding it to the `stow`
call in `.devcontainer/post-create.sh` and to the one in `dots.sh`.

The container runs as root, so `$HOME` is `/root`; on the real machine it is a
normal user's home. Never hardcode `/root` or a username in a stowed file.
Container-only behaviour goes in an env var set in `devcontainer.json`, so the
stowed file stays correct on the host where that var is unset.

niri cannot be run here (no Wayland session), so review those edits rather than
testing them. For the rest: `stow -n -v --restow --target="$HOME" zsh ssh niri`
to catch conflicts, and `zsh -ic exit` must be silent.

`~/.forgejo-token` is bind-mounted read-only and read at runtime by the git
credential helper and the forgejo MCP server. Never print or commit its value.

## Rules

Do not write comments. Write a comment only if the code is unclear without it,
or if it gives the reason for a setting that looks wrong or arbitrary.

Make the smallest change that achieves the goal. Change nothing else. Do not add
improvements, extra files, or refactors that nobody asked for.

Write every reply to the user in ASD-STE100 Simplified Technical English.
