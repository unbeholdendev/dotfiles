# dotfiles

Config for a Fedora + niri machine. Authored in this dev container, then pulled
onto the real machine. The container is for editing, not the target.

Each top-level directory holds one program's files, laid out as they sit under
`$HOME`. A `home/` module names every one of them, on a host and in a container
alike, and nothing stows anything any more. `install.sh` is the container's
script alone, and what it does now is get nix and run the switch. It names
`desktop` and `server` only to refuse them. `dots` is
the one command either way: in a container it is a function in `.zshrc` calling
that script, and on a host it is a program home-manager installs, with the clone
and the flake output written into it rather than worked out at run time. So
nothing on a host has to find the clone by resolving a file, and the profile
marker is gone with the profiles.

The name `install.sh` is not free choice. A dev container clones this repo and
runs the first of `install.sh`, `install`, `bootstrap.sh`, `bootstrap`,
`setup.sh` or `setup` it finds, with no argument. That hook is set per user,
outside any project, so a repo this one never sees still gets these files. Two
things follow: the profile falls back to `container` when `/.dockerenv` or
`/run/.containerenv` exists, and the script installs nix itself, because the
base image of somebody else's project is not ours to change. It installs zsh,
git, curl and xz the same way and for the same reason: zsh has to come from the
distro because it is the login shell, and the other three are what the nix
installer needs to run at all. Everything else comes from the store.

The nix installer wants two flags in a container. `--no-daemon`, because there
is no systemd to run one, and `--no-modify-profile`, because it otherwise
appends a line naming `/root` to the first shell file it finds, and while stow
placed `~/.zshenv` that file was this repo's. It also stops before it starts
unless `build-users-group` is empty, since a container has no `nixbld` group, so
`install.sh` writes `~/.config/nix/nix.conf` first. `sandbox` is off in the same
file, because a container is not given the privileges one wants.

`deb-agent` is a headless Debian host, and `root@deb-agent` is its home
configuration. The work happens in the dev containers it runs, not on the host,
so it wants herdr to manage the sessions and none of the agent tools itself. The
ssh table is deliberately absent there: it names the desktop's own key and every
host it reaches, none of which that host can use, and it is imported by the
desktop's module alone.

`container` is the third flake output, and it is one name for every container,
because a container hostname is a random id. The two facts that do vary are read
from the environment: the image chooses the user, so `install.sh` exports
`HOME_USER` and builds with `--impure`. A build started any other way stops with
a message saying so rather than guessing. `home/container.nix` is what `mise/`
was: nvim, fzf, zoxide, claude and forgejo-mcp, at the versions the TOML named,
pinned by `flake.lock` instead of by a version string. It carries nix itself as
well, since `install.sh` points `~/.nix-profile` away from the one the installer
made. It carries no `programs.home-manager`: that CLI is 57M of store paths, and
a container calls the activation package directly. claude-code is unfree, so the container's `pkgs` is a second import of
nixpkgs with a predicate naming that one package, because `allowUnfree` on its
own would let a second one arrive unnoticed.

`claude/` is down to `.claude/settings.json`, so every container gets the same
permissions and theme. The `.claude/` rule in `.gitignore` is anchored to the
root, because the bare pattern also matched that file. `zsh/.zshenv` puts
`~/.nix-profile/bin` ahead of `~/.local/bin`, so a pinned tool wins over one
dropped there by hand.

The container runs as root, so `$HOME` is `/root`; on the real machine it is a
normal user's home. Never hardcode `/root` or a username in a file this repo
places.
Container-only behaviour is switched by a test, never by a variable a
`devcontainer.json` sets, because these files must behave the same in a project
whose file is not ours to edit. `IS_SANDBOX` shows why: Claude Code exits rather
than run as root without it, and `claude/.claude/settings.json` asks for
`bypassPermissions` in every container these files reach, so `zsh/.zshenv`
exports it where `/.dockerenv` or `/run/.containerenv` is present.

`/nix`, `/history` and `/claude` follow the same rule. `dcup` mounts all three
and no `devcontainer.json` does, so they reach a project whose file is not ours
and no container is ever handed one twice, and no variable announces them:
`zsh/.zshenv` tests for `/claude` and sets `CLAUDE_CONFIG_DIR`, `zsh/.zshrc`
tests for `/history` and sets `ZSH_HISTFILE`, and `install.sh` repeats the first
because it runs before any shell does. `/nix` wants no variable at all, since
nix finds its store by absolute path. Each falls back to its old default where
the directory is absent, and an explicitly set variable wins over the test.

`devcontainer.json` has no Dockerfile behind it any more, only `image`, because
everything the image used to carry now has somewhere better to be: git, zsh,
curl and xz are installed by `install.sh` when they are missing, the tools come
from the store, and the git identity and credential helper are three
`git config --global` lines in `dcup`. It has no `postCreateCommand` either, so
this project is started the same way as any other, and the file is down to a
name and an image.

`/nix` is one store shared by every container, so it is fetched once rather
than each time, which is what `/mise` was for. The profile is the opposite and
must not be shared: `install.sh` points `~/.nix-profile` at
`~/.local/state/nix/profiles/profile`, under a `$HOME` that dies with the
container, or a switch in one container would replace the tools of another that
is still running. The store itself takes a lock, so two switches at once are
safe. The volume belongs to whichever container installed nix into it first, so
a project that runs as its own user rather than as root cannot write to it. That
wants the multi-user daemon, and no container these files reach needs it yet. `/history` is one per project under
`~/.devcontainer-state/` on the host, so a shell history outlives its container
without mixing with another project's. `/claude` is shared again: Claude Code
keys its sessions and its prompt history by workspace path, so one store per
person is right, and a store per project would mean a login and 153M of
downloads each.

`claude/.claude/settings.json` is linked by `install.sh` and not by a module,
because home-manager writes under `$HOME` alone and that config directory moves
with a volume that is not under it. The link is made with `ln -sfn`, so
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
tree is not ours to dirty. `dcup` asks which token this container gets, and
`none` is the first answer: one forge and not both, because a container that can
reach the other one is a container that leaks it there. A question and not a
flag, because a flag is remembered only by the person who already knows to want
it, and the answer that matters is the one nobody would have typed. With no
terminal there is nobody to answer, so nothing is copied, which is where a flag
left off. The missing file is checked before `devcontainer up`, so an hour of
image pull does not end in a container that cannot push. The forgejo token
carries the identity and a credential helper, which is the one place that names
that forge. The
github token gets neither: a fine-grained token is issued per owner, and every
owner is the same host, so the host a helper is keyed by cannot pick between two
of them, and `335420059+unbeholdendev@users.noreply.github.com` is the wrong author for somebody else's repo.
That clone names its own file and its own author instead, in a `.git/config`
which the host and the container both read, and a clone that names neither fails
its first commit, which is the right end there. A `postCreateCommand` is then
for a project's own work alone, this one included, at the price of a container
which has neither token nor identity where `none` was the answer.

The forgejo MCP server is the visible cost. It is registered at user scope in
the shared `/claude` store, so it is configured in every container, and one
started with `--token github` has no `~/.forgejo-token` for it to read and the
server does not start. That is the leak being closed, showing itself, and not a
fault to fix.

`dcclaude` is the other half of that pair: it starts claude in a container
`dcup` brought up. herdr names a pane from the comm and the argv0 of the
foreground process group it can see on the host. That is the devcontainer CLI,
which is node, and the agent is in the container, out of that process tree, so
no pane ever showed an agent and the sidebar stayed empty. `HERDR_AGENT` is the
hint for a wrapper that hides the agent, and `dcclaude` sets it on the host side
of the command, where herdr reads it from `/proc`. It is a label alone, so no
agent is installed on that host. The same variable set in the container is out
of reach, and `zsh/.zshenv` must not export it: this repo is on that host too,
where it would name every foreground process an agent. The pane is an agent
while claude runs and a shell prompt after it ends, which is what the label must
say.

That mount is provisional. This repo is to become public, and `home/ssh.nix` is
to come out of it, because that file is the only reason it must stay private: it
is a map of hosts, ports and accounts. Once it is public the hook needs no
credential, and `--dotfiles-repository` replaces both the mount and the `exec`
line, so `dcup/` gets smaller rather than larger.

`flake.nix` holds one output per host, `pycan@t460s` and `root@deb-agent`, and
one for every container. `flake.lock` is the pin that `mise/` used to be.
Home-manager runs standalone, so Fedora stays Fedora and the Debian host stays
Debian, and neither was reinstalled to get here. `extraSpecialArgs` gives each
host its two facts, the path of the clone and the name of its own output,
because a module cannot work either out and both are wanted in more than one
file. The container is given `dotfiles = null`, since its clone is at a path the
image and the mount decide, and a module that takes the path skips what it
places there.

A flake reads tracked files alone, so a new module wants `git add` before the
switch, committed or not. Home-manager stops rather than write over a file that
is already there, so anything left by hand at the path it wants is moved aside
first; `-b hm-bak` survives that collision instead, and is for the run where it
was forgotten. That is a flag and not an option, because `backupFileExtension`
belongs to the NixOS module, whose rebuild has no command line to put it on. In
a container the same job is done by `HOME_MANAGER_BACKUP_EXT`, which the
activation script reads. `install.sh` builds the activation package and runs it,
rather than calling the home-manager CLI, which is not there on a first run and
which would pull its own copy of home-manager instead of the locked one.

`foot/` was the first package across, and it shows the shape the others took.
`foot.ini` is `programs.foot.settings`, which is typed, so a key that does not
exist is an error at build rather than a line foot ignores at start. The package
comes from nixpkgs as well, because the module gives no way to take the config
alone, and a config without its package is stow with more syntax. What is left
in `foot/` is the theme noctalia renders. That one stays a link out of the store
and into the clone: the store is read only, and a file something writes cannot
live there. Every package with a rendered theme ends the same way, `yazi/` and
`noctalia/` included.

`niri/`, `portal/`, `yazi/` and `noctalia/` follow foot. Of the four, `yazi/`
alone is typed, as `programs.yazi`: its two TOML files are short, and the module
installs the tool as well, which Fedora has no package for. The rest stay files
that a module names. A 664 line `config.kdl` gains nothing from being written
twice, once in KDL and once in Nix, and a rendered theme cannot be written in
Nix at all. `portal/` is a file for a third reason: `xdg.portal` would install
the portals from nixpkgs beside Fedora's, and a portal is reached over D-Bus,
where two implementations of one interface answer at random. A file in the store
is read as it was at the switch, so an edit now wants a switch before anything
sees it, where a stow link was live. That is the price of the store, and it is
why nothing an app writes is put in it. These directories are no longer stow
packages. They are where the files live, and the module in `home/` says which
file goes where. `wireplumber/` is gone rather than moved. It held the HDMI
profile WirePlumber took over the jack, and the script that read the jack
itself, and no machine this repo now serves wants either.

`ssh/` is the last of the desktop's own, and the one the type earns most.
`programs.ssh.settings` is an attribute set of hosts, and the key and
`IdentitiesOnly` every one of them repeated are written once and merged in, so
fourteen blocks lose twenty-eight lines that had to agree. `enableDefaultConfig`
is off, because the file it replaces has no `Host *` block, and the defaults
that option adds would be new behaviour rather than the same behaviour in Nix.
`programs.ssh` installs no package: the option is null by default and the system
ssh is used.

`herdr/` and `dcup/` are deb-agent's own, and `herdr/` is the one thing in this
repo that Nix has to package itself, since it is released as a binary on GitHub
and is in no channel. `pkgs/herdr.nix` fetches that one file by hash. It is a
static PIE, with no interpreter and no NEEDED entry, so nothing has to be
patched into it and the derivation is a fetch and an install. Its `config.toml`
is a link out of the store, because herdr writes it: `onboarding` is false there
because herdr set it so after the first run. `dcup/` is two scripts and stays
two scripts, with `executable` set, because a shell script gains nothing from
being expressed in Nix. They go to `~/.local/bin`, which `.zshenv` already puts
on the path, and `dcup/` holds them at that path. The `~/.devcontainers/bin`
they had was the shape of a stow package, and it put a directory on the path of
every host and every container to serve one host.

`zsh/` and `nvim/` are files a module names rather than options written in Nix.
Neither is worth writing twice: `programs.zsh` would express in Nix what
`.zshrc` already says in zsh. What Nix does add there is the two plugins, from
nixpkgs rather than `/usr/share`, and `.zshrc` tries the profile before the
distro so one file suits a nix host and a container that has not switched yet.
`nvim-pack-lock.json` is a link out of the store on a host, because nvim writes
it on every plugin update. A container gets no such link: it is thrown away, and
a plugin update in one must not dirty the clone it was started from.

`zsh/.zshenv` is what decides which build of a tool runs. The nix installer
writes its profile into the files a login or an interactive shell reads, and a
niri session is neither, and neither is `devcontainer exec`. So without the
block at the end of that file the desktop spawns the distro build of a tool nix
owns, and a container reached by `dcclaude` finds no claude at all.
`XDG_DATA_DIRS` is set beside it, or a launcher sees no app nix installs. Both
are behind a test for the profile directory, so a shell that starts before the
first switch is untouched.

`~/.dots-path` is what that costs. `dcup` and the `dots` function used to find
the clone with `readlink -f ~/.zshrc`, which works only while stow placed that
file; from the store it resolves into `/nix`, so the fallback answered `/nix`
rather than nothing and both would carry on quietly against the wrong tree.
`dcup` was the worse of the two, since it bind-mounted the whole store at
`/dotfiles` before it failed. Neither has a fallback any more: whoever places
the config names it, and a missing name is an error. `home/dots.nix` writes the
file on a host, beside the program that holds the same path, and `install.sh`
writes it in a container, where the clone is at a path the image and the mount
decide. `.zshenv` exports `DOTFILES` from it. `dots` needs none of it on a host,
where the path is in the program, and `dcup` is the reader that keeps the file
alive.

The dark theme is `dconf.settings` in `home/theme.nix` and not two `gsettings`
lines in a script. Declared rather than set once, so a change made by hand goes
back at the next switch, and a host with no `gsettings` cannot be asked to run
it, which is what `./install.sh desktop` on deb-agent did.

niri cannot be run here (no Wayland session), so review those edits rather than
testing them. For the rest: `./install.sh container` must succeed, and must
succeed again on a second run, and `zsh -ic exit` must be silent. A `zsh -ic`
with no terminal reports `can't change option: zle` from `fzf --zsh`; that is
the missing tty and not a fault, so test that one under a pty.

The forgejo MCP server is registered at user scope, in `.claude.json` inside the
Claude store, so it loads in every project and no repository carries a
`.mcp.json` for it. That file is state in the `/claude` volume rather than one
this repo places, so a new store wants the entry once:

```
claude mcp add --scope user forgejo -- \
  sh -c 'exec forgejo-mcp --transport stdio --url https://git.home.unbeholden.dev \
    --token "$(cat "$HOME/.forgejo-token")"'
```

The `--url` is in that entry rather than an env var, because the entry serves
every project and only this one used to set `FORGEJO_URL`. Without it the server
stops with `Missing required configuration`.

`~/.forgejo-token` reaches a container by answering `forgejo` to `dcup` and no
other way, and is read there at runtime by the git credential helper and that
server. Never print or
commit its value.

`~/.github-token` is a fine-grained personal access token, and takes the same
route. It is scoped to a list of repositories under one owner, so a second owner
wants a second file. Nothing global names it: each clone points at its own file,
on the host where the clone was made, and the line survives into the container
because `.git/config` is inside the mounted tree and `$HOME` resolves on both
sides.

```
git -C <clone> config credential.https://github.com.helper \
  '!f() { echo username=<user>; echo "password=$(cat "$HOME/.github-token")"; }; f'
```

Never put the token in a remote URL. That writes it into `.git/config`, which
the container reads and a push can leak.

## Rules

Do not write comments. Write a comment only if the code is unclear without it,
or if it gives the reason for a setting that looks wrong or arbitrary.

Make the smallest change that achieves the goal. Change nothing else. Do not add
improvements, extra files, or refactors that nobody asked for.

Write every reply to the user in ASD-STE100 Simplified Technical English.
