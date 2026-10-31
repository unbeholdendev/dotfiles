# dotfiles

NixOS + niri desktop, headless host, and dev container configuration.
Desktop configuration is edited here but runs on the laptops. Container
configuration runs here; there is no Wayland session.

Program directories mirror paths under `$HOME`; modules in `home/` install
them. Nothing uses stow. `agents/` holds the prompt and skills shared by Claude
and Pi. `install.sh` links the prompt as `CLAUDE.md` or `AGENTS.md`.

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
  the user. Use `install.sh` to supply these and `CONTAINER_AGENTS`, a
  space-separated list.
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

- Pi containers install `pi/.pi/agent/extensions/project-tools` in the shared
  agent directory. The extension detects projects from their manifests and
  declared npm/pnpm workspaces, then loads Pi Lens for TypeScript projects
  and a Playwright MCP server for projects with a Playwright dependency.
  Detection reads files only; there is no manual choice or override.
- Pi Lens runs without formatting, autofix, test, and security mutations;
  diagnostics and navigation remain on. Its config seeds once at
  `$PI_CODING_AGENT_DIR/extensions/pi-lens.json`. The container profile
  provides `typescript-language-server` and `chromium`; `install.sh` installs
  the extension's pinned npm dependencies under a borrowed bun runtime, so
  no package-manager runtime enters the profile. Bun blocks playwright's
  browser-download postinstall, which is intended: Chromium comes from the
  profile. Playwright stores its output under
  `/history/pi` when the workspace state directory exists.


- `dcup` selects one or more agents. `install.sh container claude pi codex`
  installs all three. Without agent arguments it reads `~/.coding-agent`,
  then prompts in a terminal, defaulting to Claude without one. Keep the
  saved list compatible with existing single-agent files.
- `/claude`, `/pi` and `/codex` are shared across containers. Respect explicit
  `CLAUDE_CONFIG_DIR`, `PI_CODING_AGENT_DIR` and `CODEX_HOME` overrides.
- Codex's writable config seeds once with no approvals or inner sandbox and
  the Forgejo MCP server. Keep these defaults container-only. Its skills go in
  `CODEX_HOME/skills`, linked to checkouts under `CODEX_HOME/third-party`.
- With `/history` mounted, `.zshenv` sets `PI_CODING_AGENT_SESSION_DIR` to
  `/history/pi/sessions` unless explicitly overridden. `dcup` mounts a distinct
  host state directory per workspace there, so sessions survive rebuilds without
  crossing workspaces. Existing sessions in `/pi/sessions` are not moved.
- Pi's auth, settings, extensions, packages, and prompts live in its shared
  agent directory. `install.sh` copies repo settings only when `settings.json`
  is absent. Changing the seed does not update an existing volume. Keep it a
  copy: Pi rewrites settings, so a symlink would dirty the shared clone.
- Keep local package paths under `/pi` or `/dotfiles` so every container can
  resolve them.
- Keep pinned third-party skill checkouts under `third-party/`, outside
  `skills/`. Link only the intended skill groups so Pi does not discover other
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

Pi's Forgejo MCP config is linked from `pi/.pi/agent/mcp.json`; Codex's is
seeded in `codex/.codex/config.toml`. Claude needs
one user-scope registration per fresh `/claude` volume:

```
claude mcp add --scope user forgejo -- \
  sh -c 'FORGEJO_ACCESS_TOKEN="$(cat "$HOME/.forgejo-token")" \
    exec forgejo-mcp --transport stdio --url https://git.home.unbeholden.dev'
```

Use `FORGEJO_ACCESS_TOKEN`, not `--token`; Pi's `"!cat"` env form also reads it
at call time. GitHub tokens are owner-scoped: the host keeps
`~/.github-tokens/<owner>`, and `dcup` scopes the container's credential helper
to `https://github.com/<owner>`.

`~/.groq-token` is `dictate`'s desktop-only key, mode 600, written by hand and
never put in the store or offered to containers.

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
- For project-tools changes, run the committed detection tests with
  `node --test pi/.pi/agent/extensions/project-tools/detect.test.js` and
  reinstall the extension with `./install.sh container pi`. Real Pi Lens and
  Playwright behavior needs a project fixture, not this repository.
- For agent setup changes, test each affected agent explicitly. Check fresh
  settings seeding and preservation of existing settings. Agent resources come
  from the main clone even during a worktree install, so an install alone does
  not validate worktree edits to the seed, prompt, skills, or MCP config.
  Validate those files directly or in a separate test agent directory.
- For shell changes, `zsh -ic exit` must be silent under a PTY. Without a
  terminal, `fzf --zsh` reports `can't change option: zle`; that is a missing
  TTY, not a config fault.
- Review niri changes statically; it cannot run here without a Wayland session.
