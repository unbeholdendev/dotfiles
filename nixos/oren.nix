{ dotfiles, lib, modulesPath, pkgs, ... }:
{
  imports = [ "${modulesPath}/profiles/qemu-guest.nix" ];

  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 5;

  networking.hostName = "oren";

  services.qemuGuest.enable = true;
  services.openssh.enable = false;

  users.users.agent = {
    isNormalUser = true;
    shell = pkgs.zsh;
    linger = true;
  };

  # For `/etc/zshenv`, where a login shell gets the system PATH.
  programs.zsh = {
    enable = true;
    enableGlobalCompInit = false;
    interactiveShellInit = ''eval "$(${lib.getExe pkgs.direnv} hook zsh)"'';
  };

  # Agents run prebuilt binaries, such as browsers, that expect a loader path.
  programs.nix-ld.enable = true;

  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  # T3 Code, the only port open.
  networking.firewall.allowedTCPPorts = [ 3773 ];

  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "dots";
      text = ''
        git -C ${dotfiles} switch main
        git -C ${dotfiles} pull --ff-only
        nixos-rebuild switch --flake ${dotfiles}#oren
      '';
    })
    pkgs.git
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  system.stateVersion = "26.11";
}
