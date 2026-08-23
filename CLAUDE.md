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
`/run/.containerenv` exists, and the script installs stow itself, because the
base image of somebody else's project is not ours to change.

`deb-agent` is a headless Debian host that runs coding agents, on the `server`
profile. `ssh/` is deliberately absent there: the file names the desktop's own
key and every host it reaches, none of which that host can use.

`mise/` pins the tools every environment needs, whose distro version is absent
or too old: nvim, fzf and zoxide. All of them read the same file, so a version
bump is one commit rather than a command retyped per host. A tool only one
environment needs is pinned by that environment's own package instead: `herdr/`
carries its own `config.local.toml`, which mise merges, so nothing else installs
herdr. `zsh/.zshenv` puts the mise shims ahead of `~/.local/bin`, so a pinned
tool wins over one dropped there by hand. The `server` and `container` profiles
install mise if it is missing and then run `mise install`; `desktop` does not,
because Fedora's own nvim, fzf and zoxide are current.

The container runs as root, so `$HOME` is `/root`; on the real machine it is a
normal user's home. Never hardcode `/root` or a username in a stowed file.
Container-only behaviour goes in an env var set in `devcontainer.json`, so the
stowed file stays correct on the host where that var is unset.

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
