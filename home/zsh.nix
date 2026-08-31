{ pkgs, ... }:
{
  home.file.".zshenv".source = ../zsh/.zshenv;
  home.file.".zshrc".source = ../zsh/.zshrc;

  home.packages = with pkgs; [
    zsh-autosuggestions
    zsh-syntax-highlighting
  ];
}
