{ config, pkgs, ... }:
{
  imports = [
    ./common.nix
    ./dictate.nix
    ./dots.nix
    ./foot.nix
    ./herdr.nix
    ./mime.nix
    ./mpv.nix
    ./niri.nix
    ./noctalia.nix
    ./nvim.nix
    ./ssh.nix
    ./theme.nix
    ./yazi.nix
    ./zsh.nix
  ];

  home.packages = with pkgs; [
    age
    ansible
    ddcutil
    firefox
    fluxcd
    git
    jq
    kubectl
    libnotify
    libreoffice
    opentofu
    pangolin-cli
    playerctl
    signal-desktop
    sops
    sparrow
    talosctl
    thunderbird
    tor-browser
    ungoogled-chromium
    unzip
    wl-clipboard
    zip
  ];

  home.pointerCursor = {
    enable = true;
    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
  };

  home.username = "pycan";
  home.homeDirectory = "/home/pycan";

  home.file."nas".source = config.lib.file.mkOutOfStoreSymlink "/mnt/nas";

  programs.home-manager.enable = true;
}
