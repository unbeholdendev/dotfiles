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
    (writeShellApplication {
      name = "deny-pr-merge";
      runtimeInputs = [ git jq ];
      text = builtins.readFile ../agents/deny-pr-merge.sh;
    })
  ];

  xdg.configFile."git/ignore".text = ".claude/worktrees/\n";
}
