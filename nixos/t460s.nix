{ pkgs, ... }:
let
  nas = share: {
    device = "192.168.5.2:/mnt/storage/${share}";
    fsType = "nfs4";
    options = [
      # The laptop is off this LAN often, so nothing waits for the NAS at boot
      # and a read after it has gone gives up rather than hanging for ever.
      "noauto"
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "x-systemd.mount-timeout=10"
      "soft"
    ];
  };
in
{
  imports = [
    ./desktop.nix
    ./disk.nix
  ];

  networking.hostName = "t460s";
  networking.networkmanager.enable = true;

  networking.networkmanager.ensureProfiles = {
    environmentFiles = [ "/etc/nm-secrets.env" ];

    profiles.unbeholden = {
      connection = {
        id = "unbeholden";
        type = "wifi";
      };
      wifi = {
        ssid = "unbeholden";
        cloned-mac-address = "permanent";
      };
      wifi-security = {
        key-mgmt = "wpa-psk";
        psk = "$WIFI_PSK";
      };
      ipv4.method = "auto";
      ipv6.method = "auto";
    };
  };

  fileSystems."/mnt/nas/pycan" = nas "pycan";
  fileSystems."/mnt/nas/media" = nas "media";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Ten kernels and initrds is what the 2G ESP holds.
  boot.loader.systemd-boot.configurationLimit = 10;

  # What `nixos-generate-config` writes that `includeDefaultModules` does not.
  boot.initrd.availableKernelModules = [
    "rtsx_pci_sdmmc"
    "usb_storage"
  ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.supportedFilesystems = {
    exfat = true;
    ntfs = true;
  };

  zramSwap.enable = true;

  hardware.cpu.intel.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;

  # Mesa carries no VAAPI for this Gen9 chip, so gpu-screen-recorder finds no
  # h264 encoder and quits on vaInitialize.
  hardware.graphics.extraPackages = [ pkgs.intel-media-driver ];

  # ddcutil, which is how the bar reaches the external monitor's brightness.
  hardware.i2c.enable = true;

  hardware.bluetooth = {
    enable = true;
    # The bar switches it on over D-Bus, so the daemon still starts at boot.
    powerOnBoot = false;
  };

  services.printing.enable = true;
  hardware.printers = {
    # `everywhere` asks the printer for its PPD, so ensure-printers fails
    # whenever the printer is off or the laptop is off this LAN.
    ensurePrinters = [{
      name = "hp";
      deviceUri = "ipp://192.168.3.181/ipp/print";
      model = "everywhere";
    }];
    ensureDefaultPrinter = "hp";
  };

  services.tailscale.enable = true;

  services.fwupd.enable = true;
  services.thermald.enable = true;

  # The bar's battery and power-profile widgets.
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="power_supply", KERNEL=="BAT*", ATTR{charge_control_end_threshold}="80"
  '';

  time.timeZone = "Europe/Prague";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  users.users.pycan = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "video" "wheel" ];
    shell = pkgs.zsh;
  };

  # For `/etc/zshenv`, where a login shell gets the system PATH. The compinit
  # goes, not the completion, or `/share/zsh` goes with it.
  programs.zsh = {
    enable = true;
    enableGlobalCompInit = false;
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.optimise.automatic = true;

  system.stateVersion = "26.11";
}
