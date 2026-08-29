{ ... }:
{
  home.username = "pycan";
  home.homeDirectory = "/home/pycan";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  # Every file this will manage is a stow link until its package moves, and
  # home-manager stops rather than write over a file that is already there.
  home.backupFileExtension = "hm-bak";
}
