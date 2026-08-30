{ ... }:
{
  imports = [
    ./dcup.nix
    ./herdr.nix
  ];

  home.username = "root";
  home.homeDirectory = "/root";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
