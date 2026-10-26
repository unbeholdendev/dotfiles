{ pkgs, hermes, ... }:
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

  home.packages = [ hermes.packages.${pkgs.stdenv.hostPlatform.system}.minimal ];

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    settings.credential."https://git.unbeholden.dev".helper =
      ''!f() { echo username=agent; echo "password=$(cat "$HOME/.forgejo-token")"; }; f'';
  };
}
