# dotfiles

Config for a NixOS + niri machine, authored in this dev container and pulled
onto the real machine. The container is for editing, not the target.

Each top-level directory holds one program's files, laid out as they sit under
`$HOME`, and a module in `home/` names every one of them. Nothing stows
anything.

`flake.nix` has three outputs: `pycan@t460s`, the desktop; `root@oren`, a
headless host whose work happens in the dev containers it runs; and `container`,
which is one name for every container, since a container hostname is a random
id. `nixosConfigurations.t460s` is the system half of that desktop.
`flake.lock` is the pin. Home-manager runs standalone on the other two, so
Debian stays Debian.

`dots` is the one command. On a host it is a program home-manager installs, with
the clone and the flake output written into it. In a container it is a function
in `.zshrc` calling `install.sh`, which is the container's script alone and
refuses `desktop` and `server`. The name `install.sh` is not free choice: the
dev container dotfiles hook runs the first of `install.sh`, `install`,
`bootstrap.sh`, `bootstrap`, `setup.sh` or `setup` it finds, with no argument,
in a project this repo never sees.

`dcup` and `dcclaude` are oren's own. `dcup` wraps `devcontainer up` with
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
- `install.sh` cds to its own directory, so a run from a worktree switches the
  container from that worktree, but `~/.dots-path` and the claude links name
  the main clone, `/dotfiles` where it exists: `/claude` is shared by every
  container, and a worktree is deleted.
- The store is read only, so nothing an app writes can live there. A rendered
  theme, or a lock file an app rewrites, stays a `mkOutOfStoreSymlink` into the
  clone; a container gets no such link, or an update there dirties the clone it
  was started from.
- A store file is read as it was at the switch, so an edit wants a switch before
  anything sees it.
- Home-manager stops rather than write over a file already at the path it wants.
  `-b hm-bak` is the flag for a host, `HOME_MANAGER_BACKUP_EXT` for a container,
  and `home-manager.backupFileExtension` on NixOS, where there is no flag.
- `container` is built with `--impure` and reads `HOME_USER` and `HOME` from the
  environment, because the image chooses the user.
- `~/.dots-path` names the clone, since `~/.zshrc` now resolves into the store.
  `home/dots.nix` writes it on a host and `install.sh` in a container; `.zshenv`
  exports `DOTFILES` from it, and `dcup` is the reader.
- `home/t460s.nix` is the standalone home and the NixOS module both, so
  `home.username` and `home.homeDirectory` stay in it: the NixOS module sets the
  same values, and equal definitions merge.
- `nixos` is the third `extraSpecialArgs` fact, and `home/dots.nix` is the one
  reader. On NixOS one rebuild applies both, so `dots` runs `nixos-rebuild`.
- `noctalia` is the nixpkgs attribute, not `noctalia-shell`, which is the old
  name, left behind at 4.7.7.
- `xwayland-satellite` is there for handy, not for any X11 app. niri strips
  `DISPLAY` from what it spawns when no X server is up, handy's enigo then fails
  to construct, and handy 0.9.1 reads that handle before it dispatches, so every
  paste dies on `Enigo state not initialized` and never reaches the wtype it
  would have used. Upstream moved the read in v0.9.6; when nixpkgs carries that,
  this stops holding handy up and is only an X11 convenience.
- `nixos/disk.nix` is disko and owns every local `fileSystems` entry. The NAS
  mount in `nixos/t460s.nix` is the one that is not local. Confirm the disk at
  the top of `disk.nix` with `lsblk`, since disko erases what it is given.
  `hardware-configuration.nix` is not committed: the initrd list is in
  `nixos/t460s.nix`.
- `wtype` is there for handy, which finds it on PATH and declares it nowhere.
  Take it away and dictation records and transcribes and types nothing. Handy
  rewrites `settings_store.json` whole on every change, through the symlink, so
  it is a `mkOutOfStoreSymlink` like noctalia's and its window dirties the
  clone. That file is under `~/.local/share`, not `~/.config`: tauri-plugin-store
  resolves a relative name against `BaseDirectory::AppData`, which on Linux is
  `dirs::data_dir()`. It sits with the models handy downloads. The repo seeds `push_to_talk` alone, because Mod+D is a toggle and the
  default is hold; everything else in that file is what a real run wrote. Do not
  hand-write a key there, since one enum spelt wrong loses the lot.
- The `Mod+Alt` recording binds go through `noctalia/screen_recorder`, a plugin
  noctalia fetches from github and no part of the flake. It is enabled by
  `noctalia msg plugins enable noctalia/screen_recorder`, which writes
  `[plugins].enabled` into the tracked `settings.toml`, and its own options
  (codec, folder, replay buffer) live in noctalia's state, not here.
  `programs.gpu-screen-recorder.enable` is the other half: the plain package
  captures nothing without the wrapper that option installs.

## Secrets

`~/.forgejo-token` and `~/.github-token` reach a container by answering `dcup`
and no other way, and one container gets one of them, never both. Never print
or commit either value, and never put a token in a remote URL: that writes it
into `.git/config`, which the container reads and a push can leak.

`/etc/nm-secrets.env` holds `WIFI_PSK`, mode 600, and is written by hand on the
desktop. Never put the value in `nixos/t460s.nix`: `ensureProfiles` renders each
profile into the store, which is world readable. `EnvironmentFile` has no `-`
prefix, so a missing file fails `NetworkManager-ensure-profiles.service` and the
profile is never written.

The forgejo MCP server is registered at user scope in `.claude.json` inside the
`/claude` volume, so it loads in every project and a new store wants the entry
once:

```
claude mcp add --scope user forgejo -- \
  sh -c 'exec forgejo-mcp --transport stdio --url https://git.unbeholden.dev \
    --token "$(cat "$HOME/.forgejo-token")"'
```

A fine-grained github token is issued per owner and every owner is the same
host, so the host keeps one file per owner in `~/.github-tokens/<owner>`, and
`dcup` asks which one and scopes the helper to `https://github.com/<owner>`.

## Testing

niri cannot be run here (no Wayland session), so review those edits rather than
testing them. The NixOS half is checked by evaluation:

```
nix eval .#nixosConfigurations.t460s.config.system.build.toplevel.drvPath
```

For the rest: `./install.sh container` must succeed, and must succeed again on a
second run, and `zsh -ic exit` must be silent. Test that one under a pty; with
no terminal `fzf --zsh` reports `can't change option: zle`, which is the missing
tty and not a fault.
