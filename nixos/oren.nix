{ dotfiles, modulesPath, pkgs, ... }:
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

  networking = {
    hostName = "oren";
    useDHCP = false;
    interfaces.ens18.ipv4.addresses = [{ address = "192.168.4.101"; prefixLength = 24; }];
    defaultGateway = "192.168.4.1";
    nameservers = [ "192.168.4.1" ];
  };

  services.qemuGuest.enable = true;
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
      AllowUsers = [ "root" ];
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP14ZKie7ITD7Qj64XLf2JZQmo5d30Hh2HYwhrOKpJ+Y t14"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJJKC+NQ6TYLkWQ09hcMh+YKrXoo7+pE3U4U1V71Xkf8 t460s"
  ];

  users.users.agent = {
    isNormalUser = true;
    shell = pkgs.zsh;
    linger = true;
  };

  # For `/etc/zshenv`, where a login shell gets the system PATH.
  programs.zsh = {
    enable = true;
    enableGlobalCompInit = false;
  };

  # Playwright's browsers are prebuilt for Ubuntu 24.04, hence the pinned sonames.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      cairo
      cups
      dbus
      enchant
      expat
      flite
      fontconfig
      freetype
      gdk-pixbuf
      glib
      graphene
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-base
      gst_all_1.gstreamer
      gtk3
      gtk4
      harfbuzz
      harfbuzzFull
      hyphen
      icu74
      lcms2
      libavif
      libdrm
      libepoxy
      libevent
      libgbm
      libgcrypt
      libgpg-error
      libjpeg8
      libmanette
      libopus
      libpng
      libpsl
      libsecret
      libtasn1
      libwebp
      libxkbcommon
      libxml2_13
      libxslt
      mesa
      nghttp2
      nspr
      nss
      pango
      sqlite
      vulkan-loader
      wayland
      woff2
      xorg.libX11
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXrandr
      xorg.libxcb
      xorg.libxshmfence
    ];
  };
  # WebKit finds Mesa's EGL vendor and GBM backends in /run/opengl-driver.
  hardware.graphics.enable = true;
  # Playwright checks browser libraries with ldd, which cannot see nix-ld's.
  environment.variables.PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "1";

  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

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
