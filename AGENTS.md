# dotfiles

NixOS + niri desktop, headless host, and dev container configuration.
Desktop configuration is edited here but runs on the laptops. Container
configuration runs here; there is no Wayland session.

Program directories mirror paths under `$HOME`; modules in `home/` install
them. `agents/` holds the prompt shared by Claude
and Codex. `install.sh` links the prompt as `CLAUDE.md` or `AGENTS.md`.

## Nix and installation

- Use `$HOME` or the configured home directory in shared scripts and config.
  Keep fixed usernames and home paths in host-specific Nix configuration.
- Stage new files before a flake build or evaluation: Git flakes omit
  untracked files.
- `install.sh` is container-only. Hosts use `dots`; on NixOS that applies both
  system and home configuration with `nixos-rebuild`.
- Keep the name `install.sh` and its no-argument container detection: the dev
  container dotfiles hook discovers and runs it in projects we do not control.
- Detect containers with `/.dockerenv` or `/run/.containerenv`, not a variable
  supplied by another project's `devcontainer.json`. Detect optional shared
  mounts by directory existence and preserve the fallback when absent.
- Container builds need `--impure`, `HOME_USER`, and `HOME`; the image chooses
  the user. Use `install.sh` to supply these.
- `install.sh` builds from its own directory, including when run in a worktree.
  Agent links and the settings seed instead use the main clone, preferring
  `/dotfiles`. Keep shared-volume links and `~/.dots-path` pointed there:
  a disposable worktree may disappear or be inaccessible to another container.
- Store-backed files reflect the last switch. Apply a switch before expecting
  an edit to take effect; out-of-store links are the exception.
- Files an app rewrites must stay writable. Host configuration can use
  `mkOutOfStoreSymlink` into the clone; container apps must not dirty the clone
  through writable config links.
- Home-manager refuses to overwrite existing files. Use `-b hm-bak` for a
  standalone host, `HOME_MANAGER_BACKUP_EXT` for container activation, and
  `home-manager.backupFileExtension` on NixOS.
- Keep `home.username` and `home.homeDirectory` in `home/laptop.nix`: it serves
  both standalone home-manager and NixOS, whose equal definitions merge.

## Shared agent state

- Every container installs Claude and Codex; there is no selection.
- `dcup` runs one T3 Code server per container, its state in `/history/t3` so
  threads and pairings survive a rebuild, and forwards a per-workspace host
  port claimed under `~/.devcontainer-state/t3-ports`. It listens on every host
  interface, with the pairing code the only gate, so the host must stay off
  public networks. Do not add T3 Connect: nothing here needs a third party.
- `dcup` asks once per workspace whether to enable T3's browser, and keeps the
  answer in the workspace's state as `t3-browser`. Enabled, `install.sh` installs
  its libraries with the distro's package manager, where a failure must not stop
  the install, and it runs unsandboxed as root: use it only for the workspace's
  own dev servers.
- With no config in the workspace, `dcup` writes `.devcontainer.json` and hides
  it in `.git/info/exclude`.
- `dcup` gives a repo with any remote outside Forgejo or the GitHub token's
  account its own clone of the dotfiles at `/dotfiles`: `--mount` cannot be
  read-only. It sits beside the workspace's state, never inside: `/history`
  could swap it for a link to the host clone. It is made once; delete it to refresh. Never run git
  on the host inside it, as the container can write its hooks and config.
- `/claude` and `/codex` are shared across containers. Respect explicit
  `CLAUDE_CONFIG_DIR` and `CODEX_HOME` overrides.
- Codex's writable config seeds once with no approvals or inner sandbox. Keep
  these defaults container-only. Its skills go in
  `CODEX_HOME/skills`, linked to checkouts under `CODEX_HOME/third-party`.
- Keep pinned third-party skill checkouts under `third-party/`, outside
  `skills/`. Link only the intended skill groups so agents do not discover other
  providers' or unfinished skills.

## Desktop

- Let Noctalia render its themes. A template output linked into a clone that
  does not yet exist breaks a fresh install.
- `nixos/disk.nix` owns local filesystem configuration. NAS mounts are separate
  in `nixos/laptop.nix`. Before running disko, confirm the target host's disk
  with `lsblk` against `nixos/t460s.nix` or `nixos/t14.nix`: disko erases it.
  Keep initrd modules in the shared and host NixOS modules rather than committing
  `hardware-configuration.nix`.
- Recording binds require both the `noctalia/screen_recorder` plugin and
  `programs.gpu-screen-recorder.enable`; the plain package lacks the capture
  wrapper. Enable the plugin with
  `noctalia msg plugins enable noctalia/screen_recorder`. Plugin enablement is
  tracked in Noctalia's `settings.toml`; recorder options live in plugin state.

## Secrets

`dcup` copies the selected Forgejo or GitHub token into a new container, never
both. Never print or commit tokens, put them in remote URLs, or pass them in
argv. Read them at call time from their files.

Agents and T3 Code both reach Forgejo through `tea`, so the token needs
`read:user`, or T3 Code cannot read PRs and `tea login add` refuses it. `dcup`
logs `tea` in only when it creates a container.

The host keeps one GitHub token, `~/.github-token`; `dcup` asks GitHub for its
account. In the container it logs `gh` in and sets git's identity to that
account, as nothing else gives GitHub containers one.

`~/.groq-token` is `dictate`'s desktop-only key, mode 600, written by hand and
never put in the store or offered to containers.

## Public mirror

Main is mirrored to a public GitHub repo with no check before the push, and
force-pushes cannot reliably remove anything from it. Stage files by name.
Commits, including messages and trailers, must not hold private hosts, public
IPs, employer or client names, or private emails. SSH hosts belong in
`~/.ssh/config.local` and private `dictate` vocabulary in `~/.dictate-terms`;
both are untracked and written by hand.

## Testing

Choose checks for the files changed. Documentation-only edits need review and
`git diff --check`, not an activation.

- For NixOS changes, evaluate both laptops:

  ```
  nix eval .#nixosConfigurations.t460s.config.system.build.toplevel.drvPath
  nix eval .#nixosConfigurations.t14.config.system.build.toplevel.drvPath
  ```

- For launcher or installer changes, run
  `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest test_install.py dcup/test_launchers.py`.
- For installer or container home configuration changes, run
  `./install.sh container` twice and check both runs succeed. This activates the
  worktree's Nix configuration in the running container; it is not a dry run.
- For agent setup changes, test each affected agent explicitly. Check fresh
  settings seeding and preservation of existing settings. Agent resources come
  from the main clone even during a worktree install, so an install alone does
  not validate worktree edits to the seed, prompt, skills, or MCP config.
  Validate those files directly or in a separate test agent directory.
- For shell changes, `zsh -ic exit` must be silent under a PTY. Without a
  terminal, `fzf --zsh` reports `can't change option: zle`; that is a missing
  TTY, not a config fault.
- Review niri changes statically; it cannot run here without a Wayland session.
