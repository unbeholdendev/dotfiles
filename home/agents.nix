{ pkgs, ... }:
{
  home.packages = with pkgs; [
    claude-code
    codex
    gh
    jq
    t3code
    tea
    (writeShellApplication {
      name = "deny-pr-merge";
      runtimeInputs = [ jq ];
      text = builtins.readFile ../agents/deny-pr-merge.sh;
    })
  ];

  xdg.configFile."git/ignore".text = ".claude/worktrees/\n";
}
