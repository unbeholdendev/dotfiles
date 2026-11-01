{ pkgs, ... }:
let
  fromEnv = name:
    let v = builtins.getEnv name;
    in if v != "" then v else throw "${name} is empty: run install.sh, not nix build";
in
{
  imports = [
    ./common.nix
    ./nvim.nix
    ./zsh.nix
  ];

  # nix, because install.sh points ~/.nix-profile away from the installer's.
  home.packages = with pkgs; [ claude-code codex nix t3code tea util-linux ];

  xdg.configFile."git/ignore".text = ".claude/worktrees/\n";

  # A container has no user systemd, and nobody reads a man page in one.
  systemd.user.enable = false;
  programs.man.enable = false;
  manual.manpages.enable = false;

  home.username = fromEnv "HOME_USER";
  home.homeDirectory = fromEnv "HOME";
}
