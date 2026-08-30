{ pkgs, ... }:
{
  imports = [
    ./dcup.nix
    ./dots.nix
    ./herdr.nix
    ./nvim.nix
    ./zsh.nix
  ];

  # What `mise/` pinned for this host. Its config stays stowed for the
  # container, which still has no nix.
  home.packages = with pkgs; [
    neovim
    fzf
    zoxide
  ];

  home.username = "root";
  home.homeDirectory = "/root";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
