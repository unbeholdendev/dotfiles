# dotfiles

NixOS and niri on two ThinkPads, plus Home Manager config for a headless host
and dev containers. Program directories mirror paths under `$HOME`; modules in
`home/` install them.

This is a mirror of my private repo. Issues and pull requests are welcome. I
apply changes in the private repo, and they reach main here from there.

## Before you run any of this

- `install.sh` installs Nix if it's missing and activates Home Manager over your
  home directory. Keep it to a disposable container.
- The Claude Code and Codex defaults turn off permission prompts, and Codex's
  sandbox too. In a container, that's what I want. On your own machine it
  probably isn't.
- Running disko with `nixos/disk.nix` erases the target disk.
- The config expects my username, my home paths and my Forgejo server. Change
  them first.

## Files you won't find here

- `~/.ssh/config.local` holds my SSH hosts.
- `~/.dictate-terms` adds words to the `dictate` transcription prompt.
