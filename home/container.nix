{ pkgs, lib, pi, ... }:
let
  fromEnv = name:
    let v = builtins.getEnv name;
    in if v != "" then v else throw "${name} is empty: run install.sh, not nix build";

  agents =
    let a = builtins.getEnv "CONTAINER_AGENTS";
    in lib.splitString " " (if a == "" then "claude" else a);
in
{
  imports = [
    ./common.nix
    ./nvim.nix
    ./zsh.nix
  ];

  # nix, because install.sh points ~/.nix-profile away from the installer's.
  home.packages = with pkgs; [ forgejo-mcp nix ]
    ++ lib.optionals (builtins.elem "claude" agents) [ claude-code ]
    ++ lib.optionals (builtins.elem "codex" agents) [ codex ]
    ++ lib.optionals (builtins.elem "pi" agents) [
      pi.packages.${pkgs.stdenv.hostPlatform.system}.default
      typescript-language-server
      chromium
    ];

  xdg.configFile."git/ignore".text = ".claude/worktrees/\n";

  # A container has no user systemd, and nobody reads a man page in one.
  systemd.user.enable = false;
  programs.man.enable = false;
  manual.manpages.enable = false;

  home.username = fromEnv "HOME_USER";
  home.homeDirectory = fromEnv "HOME";
}
