{ pkgs, ... }:
{
  home.file.".zshenv".source = ../zsh/.zshenv;
  home.file.".zshrc".source = ../zsh/.zshrc;

  # `.zshrc` sources these by path, and tries the nix profile before the distro.
  home.packages = with pkgs; [
    zsh-autosuggestions
    zsh-syntax-highlighting
  ];
}
