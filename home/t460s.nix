{ config, pkgs, ... }:
{
  imports = [
    ./common.nix
    ./dots.nix
    ./foot.nix
    ./handy.nix
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
    ansible
    ddcutil
    firefox
    git
    grim
    handy
    jq
    kdePackages.kdenlive
    libnotify
    pangolin-cli
    playerctl
    signal-desktop
    swappy
    ungoogled-chromium
    unzip
    wl-clipboard
    wtype
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
