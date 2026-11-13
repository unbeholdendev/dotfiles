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

## Installing oren

`oren` is the headless VM. Install it from the NixOS installer ISO, as root:

1. Check the target disk. disko erases
   `/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0`, the VM's `scsi0`;
   confirm it with `lsblk` and `ls -l /dev/disk/by-id/`.
2. Partition and mount it, then put root's clone at `/srv/dotfiles` on the new
   system and install from it:

   ```sh
   export NIX_CONFIG='experimental-features = nix-command flakes'
   nix-shell -p git --run 'git clone <repo-url> /tmp/dotfiles'
   nix run github:nix-community/disko -- --mode destroy,format,mount --flake /tmp/dotfiles#oren
   nix-shell -p git --run 'git clone <repo-url> /mnt/srv/dotfiles'
   nixos-install --flake /mnt/srv/dotfiles#oren
   reboot
   ```

3. Log in as root over SSH. Write the Forgejo and GitHub tokens to
   `~agent/.forgejo-token` and `~agent/.github-token`, owned by `agent`, mode
   600. Run `dots`, then `systemctl restart home-manager-agent` so the
   activation logs `tea` and `gh` in and reruns the agent setup.
4. Pair a T3 Code client with `su - agent -c t3pair`.
