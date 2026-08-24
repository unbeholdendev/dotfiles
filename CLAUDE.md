# dotfiles

Config for a Fedora + niri machine. Authored in this dev container, then pulled
onto the real machine. The container is for editing, not the target.

Each top-level directory is a stow package whose interior mirrors `$HOME`:
`zsh/`, `ssh/`, `niri/`, `nvim/`. `install.sh` is the only entry point. It
takes a profile, `desktop`, `server` or `container`, and the table at the top of
it is the one place where the environments differ. Adding a package means adding
it to the profiles whose environment runs its tool; anywhere else it is an inert
link. niri and foot cannot run in the container at all.

The name `install.sh` is not free choice. A dev container clones this repo and
runs the first of `install.sh`, `install`, `bootstrap.sh`, `bootstrap`,
`setup.sh` or `setup` it finds, with no argument. That hook is set per user,
outside any project, so a repo this one never sees still gets these files. Two
things follow: the profile falls back to `container` when `/.dockerenv` or
`/run/.containerenv` exists, and the script installs stow and the zsh plugins
itself, because the base image of somebody else's project is not ours to
change.

`deb-agent` is a headless Debian host, on the `server` profile. The work happens
in the dev containers it runs, not on the host, so it wants herdr to manage the
sessions and none of the agent tools itself. `ssh/` is deliberately absent
there: the file names the desktop's own key and every host it reaches, none of
which that host can use.

`mise/` pins the tools every environment needs, whose distro version is absent
or too old: nvim, fzf and zoxide. All of them read the same file, so a version
bump is one commit rather than a command retyped per host. A tool one profile
alone needs is pinned by a package only that profile stows, in its own file
under `.config/mise/conf.d/`, which mise merges with the shared one: `herdr/`
for the server, `claude/` for the container, which is where claude and
forgejo-mcp are wanted. Each file is named after its package, so two of them can
never collide. forgejo-mcp needs an explicit `forgejo:` backend, whose default
host is Codeberg, where it is released. `claude/` also holds
`.claude/settings.json`, which `post-create.sh` used to write, so every
container gets the same permissions and theme rather than only this one. The
`.claude/` rule in `.gitignore` is anchored to the root, because the bare
pattern also matched that file. `zsh/.zshenv` puts the mise shims ahead of
`~/.local/bin`, so a pinned tool wins over one dropped there by hand. The
`server` and `container` profiles install mise if it is missing and then run
`mise install`; `desktop` does not, because Fedora's own builds are current.

The container runs as root, so `$HOME` is `/root`; on the real machine it is a
normal user's home. Never hardcode `/root` or a username in a stowed file.
Container-only behaviour goes in an env var set in `devcontainer.json`, so the
stowed file stays correct on the host where that var is unset. That file has no
Dockerfile behind it any more, only `image`, because everything the image used
to carry now has somewhere better to be: git, zsh, stow and the zsh plugins are
installed by `install.sh` when they are missing, the tools come from mise, and
the git identity and credential helper are `GIT_CONFIG_*` variables, which keeps
them in this project rather than in every container these files reach.

`/mise` is the exception to that env var rule. It is a shared volume holding the
mise store, so one download serves every container rather than 385M each, and an
external project's `devcontainer.json` is not ours to add a var to. So
`zsh/.zshenv` and `install.sh` test for the directory and set `MISE_DATA_DIR`
themselves, and both fall back to `~/.local/share/mise` where it is absent. An
explicitly set `MISE_DATA_DIR` wins over the test.

niri cannot be run here (no Wayland session), so review those edits rather than
testing them. For the rest: `./install.sh container` must succeed, a package
added to the `desktop` profile must stow into an empty directory without
conflicts, and `zsh -ic exit` must be silent.

`~/.forgejo-token` is bind-mounted read-only and read at runtime by the git
credential helper and the forgejo MCP server. Never print or commit its value.

## Rules

Do not write comments. Write a comment only if the code is unclear without it,
or if it gives the reason for a setting that looks wrong or arbitrary.

Make the smallest change that achieves the goal. Change nothing else. Do not add
improvements, extra files, or refactors that nobody asked for.

Write every reply to the user in ASD-STE100 Simplified Technical English.
