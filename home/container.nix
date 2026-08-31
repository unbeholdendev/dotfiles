{ pkgs, ... }:
let
  fromEnv = name:
    let v = builtins.getEnv name;
    in if v != "" then v else throw "${name} is empty: run install.sh, not nix build";
in
{
  imports = [
    ./nvim.nix
    ./zsh.nix
  ];

  # nix, because install.sh points ~/.nix-profile away from the installer's.
  home.packages = with pkgs; [
    claude-code
    forgejo-mcp
    fzf
    neovim
    nix
    zoxide
  ];

  home.file.".config/git/ignore".text = ".claude/worktrees/\n";

  home.username = fromEnv "HOME_USER";
  home.homeDirectory = fromEnv "HOME";
  home.stateVersion = "26.05";
  news.display = "silent";

}
