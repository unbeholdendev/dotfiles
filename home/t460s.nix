{ config, pkgs, ... }:
{
  imports = [
    ./common.nix
    ./dots.nix
    ./foot.nix
    ./niri.nix
    ./noctalia.nix
    ./nvim.nix
    ./portal.nix
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
    jq
    libnotify
    playerctl
    signal-desktop
    swappy
    ungoogled-chromium
    unzip
    wl-clipboard
    zip
  ];

  home.pointerCursor = {
    enable = true;
    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
    size = 24;
  };

  home.username = "pycan";
  home.homeDirectory = "/home/pycan";

  home.file."nas".source = config.lib.file.mkOutOfStoreSymlink "/mnt/nas";

  programs.home-manager.enable = true;
}
