# dotfiles

Config for a Fedora + niri machine, authored in this dev container and pulled
onto the real machine. The container is for editing, not the target.

Each top-level directory holds one program's files, laid out as they sit under
`$HOME`, and a module in `home/` names every one of them. Nothing stows
anything.

`flake.nix` has three outputs: `pycan@t460s`, the desktop; `root@deb-agent`, a
headless host whose work happens in the dev containers it runs; and `container`,
which is one name for every container, since a container hostname is a random
id. `flake.lock` is the pin. Home-manager runs standalone, so Fedora stays
Fedora and Debian stays Debian.

`dots` is the one command. On a host it is a program home-manager installs, with
the clone and the flake output written into it. In a container it is a function
in `.zshrc` calling `install.sh`, which is the container's script alone and
refuses `desktop` and `server`. The name `install.sh` is not free choice: the
dev container dotfiles hook runs the first of `install.sh`, `install`,
`bootstrap.sh`, `bootstrap`, `setup.sh` or `setup` it finds, with no argument,
in a project this repo never sees.

`dcup` and `dcclaude` are deb-agent's own. `dcup` wraps `devcontainer up` with
a bind mount of the clone at `/dotfiles`, the three mounts below, and the
`common-utils` feature, then runs `install.sh container`. `dcclaude` starts
claude in a container `dcup` brought up.

## Constraints

- Never hardcode `/root` or a username in a file this repo places. A container
  runs as root; on the real machine `$HOME` is a normal user's.
- Container-only behaviour is switched by a test for `/.dockerenv` or
  `/run/.containerenv`, never by a variable a `devcontainer.json` sets, because
  these files must work in a project whose file is not ours to edit. The `/nix`,
  `/history` and `/claude` mounts follow the same rule: `.zshenv` and `.zshrc`
  test for the directory and fall back to the old default.
- A flake reads tracked files alone, so a new module wants `git add` before a
  switch, committed or not.
- The store is read only, so nothing an app writes can live there. A rendered
  theme, or a lock file an app rewrites, stays a `mkOutOfStoreSymlink` into the
  clone; a container gets no such link, or an update there dirties the clone it
  was started from.
- A store file is read as it was at the switch, so an edit wants a switch before
  anything sees it.
- Home-manager stops rather than write over a file already at the path it wants.
  `-b hm-bak` is the flag for a host, `HOME_MANAGER_BACKUP_EXT` for a container.
- `container` is built with `--impure` and reads `HOME_USER` and `HOME` from the
  environment, because the image chooses the user.
- `~/.dots-path` names the clone, since `~/.zshrc` now resolves into the store.
  `home/dots.nix` writes it on a host and `install.sh` in a container; `.zshenv`
  exports `DOTFILES` from it, and `dcup` is the reader.

## Secrets

`~/.forgejo-token` and `~/.github-token` reach a container by answering `dcup`
and no other way, and one container gets one of them, never both. Never print
or commit either value, and never put a token in a remote URL: that writes it
into `.git/config`, which the container reads and a push can leak.

The forgejo MCP server is registered at user scope in `.claude.json` inside the
`/claude` volume, so it loads in every project and a new store wants the entry
once:

```
claude mcp add --scope user forgejo -- \
  sh -c 'exec forgejo-mcp --transport stdio --url https://git.home.unbeholden.dev \
    --token "$(cat "$HOME/.forgejo-token")"'
```

A github clone names its own token file and its own author, because a
fine-grained token is issued per owner and every owner is the same host:

```
git -C <clone> config credential.https://github.com.helper \
  '!f() { echo username=<user>; echo "password=$(cat "$HOME/.github-token")"; }; f'
```

## Testing

niri cannot be run here (no Wayland session), so review those edits rather than
testing them. For the rest: `./install.sh container` must succeed, and must
succeed again on a second run, and `zsh -ic exit` must be silent. Test that one
under a pty; with no terminal `fzf --zsh` reports `can't change option: zle`,
which is the missing tty and not a fault.

## Rules

Do not write comments. Write a comment only if the code is unclear without it,
or if it gives the reason for a setting that looks wrong or arbitrary.

Make the smallest change that achieves the goal. Change nothing else. Do not add
improvements, extra files, or refactors that nobody asked for.

Write every reply to the user in ASD-STE100 Simplified Technical English.
