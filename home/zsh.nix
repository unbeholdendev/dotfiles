{ pkgs, ... }:
{
  home.file.".zshenv".source = ../zsh/.zshenv;
  home.file.".zshrc".source = ../zsh/.zshrc;

  home.packages = with pkgs; [
    fzf
    zoxide
    zsh-autosuggestions
    zsh-syntax-highlighting
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
