# dotfiles

NixOS + niri desktop and headless host configuration. Desktop configuration is
edited here but runs on the laptops; `oren`, the headless host, is a NixOS
Proxmox VM configured here. Agents run on `oren`; there is no Wayland session.

Program directories mirror paths under `$HOME`; modules in `home/` install
them. `agents/` holds the prompt shared by Claude and Codex, and `setup.sh`,
which links it as `CLAUDE.md` or `AGENTS.md`; `oren`'s home-manager activation
runs it.

## Nix and installation

- Use `$HOME` or the configured home directory in shared scripts and config.
  Keep fixed usernames and home paths in host-specific Nix configuration.
- Stage new files before a flake build or evaluation: Git flakes omit
  untracked files.
- Hosts use `dots`; on NixOS that applies both system and home configuration
  with `nixos-rebuild`.
- Store-backed files reflect the last switch. Apply a switch before expecting
  an edit to take effect; out-of-store links are the exception.
- Files an app rewrites must stay writable. Laptop configuration can use
  `mkOutOfStoreSymlink` into the clone; `agent` on `oren` cannot write its clone.
- Home-manager refuses to overwrite existing files. Use `-b hm-bak` for a
  standalone host and `home-manager.backupFileExtension` on NixOS.
- Keep `home.username` and `home.homeDirectory` in `home/laptop.nix`: it serves
  both standalone home-manager and NixOS, whose equal definitions merge.

## Shared agent state

- `oren` installs Claude and Codex from `home/agents.nix`. Keep the agent
  packages there, not in the host module. Claude Code is unfree: allow it by name in `agentPkgs`,
  never with `allowUnfree`, and keep the laptops on plain nixpkgs.
- `oren` runs agents and one T3 Code server on the host as the unprivileged
  user `agent`, with no dev container: a lingering systemd user unit on port
  3773, with its state in `~/.t3`. `t3pair`
  pairs with it. Derive its paths from the configured home, never `/root`.
- T3 keeps its projects only in `~/.t3`, and t3code 0.1.8 cannot declare
  them. After a reinstall, recreate them by hand. Each repo under `~agent` is
  its own project with default thread mode `worktree` and auto-pull on. Its
  worktree-create script runs `bun install` where the repo has a `bun.lock`,
  then `(cd site && bun install)` where `site/` has one too; repos without
  one get no script. A project `agent` at `/home/agent`, in local mode, serves
  read-only cross-repo work.
- Playwright's downloaded browsers load through nix-ld. When one reports a
  missing library, add it to `programs.nix-ld.libraries` in `nixos/oren.nix`;
  `playwright install --with-deps` needs root.
- `agent` must never gain root: no `wheel`, `docker` or other privileged
  group, no sudo rule, not a Nix trusted user. Root rebuilds `oren` with root's
  `dots` from the root-owned clone at `/srv/dotfiles`, which only pulls merged
  main. Never let root build from, or `agent` write to, a clone `agent` can
  change: agents edit this repo in T3 worktrees, so that would make `agent`
  root. `agent`'s config links read `/srv/dotfiles` and are read-only to it.
- On `oren`, direnv with nix-direnv loads per-project toolchains. Claude gets
  them from the SessionStart and CwdChanged hooks in its settings, which must
  do nothing where direnv is absent; Claude's shell snapshot re-exports `PATH`
  after `.zshenv`, so the hooks stay. Codex gets them from `oren`'s `.zshenv`,
  which runs direnv in non-interactive zsh: Codex runs each command that way,
  after sourcing its snapshot. direnv's whitelist
  covers only `~/.t3/worktrees/`; widen it no further. Never set `BASH_ENV` to
  run direnv: direnv starts bash, which reads it again, and the loop stalls T3.
- Respect explicit `CLAUDE_CONFIG_DIR` and `CODEX_HOME` overrides.
- Codex's writable config seeds once with no approvals or inner sandbox, and
  Claude bypasses permissions. Keep these defaults to `oren`, a disposable VM where agents run unsandboxed as an
  unprivileged user. Never apply them to the laptops. Codex's skills go in
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

On `oren` the Forgejo and GitHub tokens sit in `agent`'s home, mode 600,
placed by hand; its activation logs `tea` and `gh` in once each.
Never print or commit tokens, put them in remote URLs, or pass them in argv.
Read them at call time from their files.

Agents and T3 Code both reach Forgejo through `tea`, so the token needs
`read:user`, or T3 Code cannot read PRs and `tea login add` refuses it.

`oren`'s activation asks GitHub for the token's account and gives git that
identity for GitHub remotes.

`~/.groq-token` is `dictate`'s desktop-only key, mode 600, written by hand and
never put in the store or offered to `oren`.

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

- For NixOS changes, evaluate both laptops and `oren`:

  ```
  nix eval .#nixosConfigurations.t460s.config.system.build.toplevel.drvPath
  nix eval .#nixosConfigurations.t14.config.system.build.toplevel.drvPath
  nix eval .#nixosConfigurations.oren.config.system.build.toplevel.drvPath
  ```

  A change meant for `oren` alone must leave the laptops' drvPaths unchanged.

- For `oren` changes, also build its toplevel. Never activate or switch it
  here.
- For agent setup changes, test each affected agent explicitly. Check fresh
  settings seeding and preservation of existing settings. Run
  `agents/setup.sh` against the worktree with `CLAUDE_CONFIG_DIR` and
  `CODEX_HOME` pointed at a scratch directory, never the live ones.
- For shell changes, `zsh -ic exit` must be silent under a PTY. Without a
  terminal, `fzf --zsh` reports `can't change option: zle`; that is a missing
  TTY, not a config fault.
- Review niri changes statically; it cannot run here without a Wayland session.
