{ ... }:
{
  imports = [
    ./foot.nix
    ./niri.nix
    ./noctalia.nix
    ./portal.nix
    ./yazi.nix
  ];

  home.username = "pycan";
  home.homeDirectory = "/home/pycan";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
