{ ... }:
{
  imports = [
    ./common.nix
    ./dcup.nix
    ./dots.nix
    ./herdr.nix
    ./nvim.nix
    ./zsh.nix
  ];

  home.username = "root";
  home.homeDirectory = "/root";

  programs.home-manager.enable = true;
}
