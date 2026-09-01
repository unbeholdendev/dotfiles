{ ... }:
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

  home.username = "pycan";
  home.homeDirectory = "/home/pycan";

  programs.home-manager.enable = true;
}
