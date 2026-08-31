{ pkgs, ... }:
{
  imports = [
    ./dcup.nix
    ./dots.nix
    ./herdr.nix
    ./nvim.nix
    ./zsh.nix
  ];

  home.packages = with pkgs; [
    neovim
    fzf
    zoxide
  ];

  home.username = "root";
  home.homeDirectory = "/root";
  home.stateVersion = "26.05";
  news.display = "silent";

  programs.home-manager.enable = true;
}
