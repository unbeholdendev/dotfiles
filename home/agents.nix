{ pkgs, ... }:
{
  home.packages = with pkgs; [
    claude-code
    codex
    gh
    jq
    opencode
    t3code
    tea
  ];

  xdg.configFile."git/ignore".text = ".claude/worktrees/\n";
}
