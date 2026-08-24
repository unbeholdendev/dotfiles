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
change. In a container the clone answers to two names, the workspace and the
`/dotfiles` mount, and stow owns the links under one of them, so a run started
from the other name is handed to the mount rather than aborting on links it does
not own.

`deb-agent` is a headless Debian host, on the `server` profile. The work happens
in the dev containers it runs, not on the host, so it wants herdr to manage the
sessions and none of the agent tools itself. `ssh/` is deliberately absent
there: the file names the desktop's own key and every host it reaches, none of
which that host can use.

`mise/` pins the tools whose distro version is absent or too old: nvim, fzf and
zoxide. The `server` and `container` profiles stow it, install mise where it is
missing and run `mise install`. The desktop takes those three from Fedora, whose
builds are current, so it does not stow the package at all. A version bump is
then one commit rather than a command retyped per host. A tool one profile alone
needs is pinned by a package only that profile stows, in its own file
under `.config/mise/conf.d/`, which mise merges with the shared one: `herdr/`
for the server, `claude/` for the container, which is where claude and
forgejo-mcp are wanted. Each file is named after its package, so two of them can
never collide. forgejo-mcp needs an explicit `forgejo:` backend, whose default
host is Codeberg, where it is released. `claude/` also holds
`.claude/settings.json`, so every container gets the same permissions and theme.
The `.claude/` rule in `.gitignore` is anchored to the root, because the bare
pattern also matched that file. `zsh/.zshenv` puts the mise shims ahead of
`~/.local/bin`, so a pinned tool wins over one dropped there by hand.

The container runs as root, so `$HOME` is `/root`; on the real machine it is a
normal user's home. Never hardcode `/root` or a username in a stowed file.
Container-only behaviour is switched by a test, never by a variable a
`devcontainer.json` sets, because these files must behave the same in a project
whose file is not ours to edit. `IS_SANDBOX` shows why: Claude Code exits rather
than run as root without it, and `claude/.claude/settings.json` asks for
`bypassPermissions` in every container these files reach, so `zsh/.zshenv`
exports it where `/.dockerenv` or `/run/.containerenv` is present.

`/mise`, `/history` and `/claude` follow the same rule. `dcup` mounts all three
and no `devcontainer.json` does, so they reach a project whose file is not ours
and no container is ever handed one twice, and no variable announces them:
`zsh/.zshenv` tests for each directory and sets `MISE_DATA_DIR`, `ZSH_HISTFILE`
and `CLAUDE_CONFIG_DIR` itself, `zsh/.zshrc` reads the second, and `install.sh`
repeats the first and third because it runs before any shell does. Each falls
back to its old default where the directory is absent, and an explicitly set
variable wins over the test.

`devcontainer.json` has no Dockerfile behind it any more, only `image`, because
everything the image used to carry now has somewhere better to be: git, zsh,
stow and the zsh plugins are installed by `install.sh` when they are missing,
the tools come from mise, and the git identity and credential helper are three
`git config --global` lines in `dcup`. It has no `postCreateCommand` either, so
this project is started the same way as any other, and the file is down to a
name and an image.

`/mise` is one mise store shared by every container, so 385M is fetched once
rather than each time. `/history` is the opposite, one per project under
`~/.devcontainer-state/` on the host, so a shell history outlives its container
without mixing with another project's. `/claude` is shared again: Claude Code
keys its sessions and its prompt history by workspace path, so one store per
person is right, and a store per project would mean a login and 153M of
downloads each.

`claude/` cannot stow its `settings.json`, because the config directory moves
with that volume and stow only writes under `$HOME`. Its `.stow-local-ignore`
keeps the package from linking the file into the wrong place, and `install.sh`
links it into `CLAUDE_CONFIG_DIR` instead. That link is made with `ln -sfn`, so
it also repairs itself: Claude Code writes settings with a temp file and a
rename, which would otherwise replace the link with a plain file for good.

The desktop never runs a dev container; deb-agent does. So `dcup/` is on the
`server` profile alone. It wraps `devcontainer up` with the flags that put these
files into a project whose image is not ours to change: a bind mount of the
clone on that host, the three mounts above, and the `common-utils`
feature, which is the only way to get zsh into such a project as the login
shell. It mounts rather than using the CLI's own dotfiles hook, because that
hook clones, and this repo is private, so it would need a Forgejo credential
inside a project that is not ours. The mount cannot be read-only, because the
CLI validates `--mount` against a regex that takes only type, source, target and
external, so a container can write to the clone on that host. Anything after the
folder argument is passed straight to `devcontainer up`, which is where a
per-project difference goes. `--no-lockfile` is there because the CLI otherwise
writes `devcontainer-lock.json` into the project it starts, and that project's
tree is not ours to dirty. `dcup --token` copies `~/.forgejo-token` in and sets
the git identity and the credential helper, which is the one place that names
the forge. A flag and not the default: that identity is wrong in a project
shared with other people, and the credential is worth more to them than the MCP
server is to us. A `postCreateCommand` is then for a project's own work alone,
this one included, at the price of a container which has neither token nor
identity where the flag was forgotten.

That mount is provisional. This repo is to become public, and `ssh/` is to come
out of it, because that package is the only reason it must stay private: the
file is a map of hosts, ports and accounts. Once it is public the hook needs no
credential, and `--dotfiles-repository` replaces both the mount and the `exec`
line, so `dcup/` gets smaller rather than larger.

niri cannot be run here (no Wayland session), so review those edits rather than
testing them. For the rest: `./install.sh container` must succeed, a package
added to the `desktop` profile must stow into an empty directory without
conflicts, and `zsh -ic exit` must be silent.

The forgejo MCP server is registered at user scope, in `.claude.json` inside the
Claude store, so it loads in every project and no repository carries a
`.mcp.json` for it. That file is state in the `/claude` volume rather than a
stowed file, so a new store wants the entry once:

```
claude mcp add --scope user forgejo -- \
  sh -c 'exec forgejo-mcp --transport stdio --url https://git.home.unbeholden.dev \
    --token "$(cat "$HOME/.forgejo-token")"'
```

The `--url` is in that entry rather than an env var, because the entry serves
every project and only this one used to set `FORGEJO_URL`. Without it the server
stops with `Missing required configuration`.

`~/.forgejo-token` reaches a container through `dcup --token` alone, and is read
there at runtime by the git credential helper and that server. Never print or
commit its value.

## Rules

Do not write comments. Write a comment only if the code is unclear without it,
or if it gives the reason for a setting that looks wrong or arbitrary.

Make the smallest change that achieves the goal. Change nothing else. Do not add
improvements, extra files, or refactors that nobody asked for.

Write every reply to the user in ASD-STE100 Simplified Technical English.
