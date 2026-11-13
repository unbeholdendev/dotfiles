# dotfiles

NixOS and niri on two ThinkPads, and NixOS on a headless Proxmox VM. Program directories mirror paths under
`$HOME`; modules in `home/` install them.

This is a mirror of my private repo.

## Before you run any of this

- The Claude Code and Codex defaults turn off permission prompts, and Codex's
  sandbox too. On the disposable headless VM that runs them as an
  unprivileged user, that's what I want. On your own
  machine it probably isn't.
- Running disko with `nixos/disk.nix` erases the target disk.
- The config expects my username, my home paths and my Forgejo server. Change
  them first.

## Files you won't find here

- `~/.ssh/config.local` holds my SSH hosts.
- `~/.dictate-terms` adds words to the `dictate` transcription prompt.
