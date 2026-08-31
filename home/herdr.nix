{ config, dotfiles, pkgs, ... }:
{
  home.packages = [ (pkgs.callPackage ../pkgs/herdr.nix { }) ];

  xdg.configFile."herdr/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink
      "${dotfiles}/herdr/.config/herdr/config.toml";
}
