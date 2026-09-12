{ config, dotfiles, pkgs, ... }:
{
  home.packages = [ pkgs.herdr ];

  xdg.configFile."herdr/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink
      "${dotfiles}/herdr/.config/herdr/config.toml";
}
