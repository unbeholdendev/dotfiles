{ config, pkgs, ... }:
{
  home.packages = [ (pkgs.callPackage ../pkgs/herdr.nix { }) ];

  # herdr writes this file itself: `onboarding` is false because herdr set it so
  # after the first run. The store holds nothing that is written.
  xdg.configFile."herdr/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/dotfiles/herdr/.config/herdr/config.toml";
}
