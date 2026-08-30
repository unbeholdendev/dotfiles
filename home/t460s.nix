{ ... }:
{
  imports = [
    ./foot.nix
    ./niri.nix
    ./noctalia.nix
    ./nvim.nix
    ./portal.nix
    ./ssh.nix
    ./yazi.nix
    ./zsh.nix
  ];

  home.username = "pycan";
  home.homeDirectory = "/home/pycan";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
