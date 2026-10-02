{ config, dotfiles, pkgs, ... }:
{
  xdg.stateFile."noctalia/settings.toml".source =
    config.lib.file.mkOutOfStoreSymlink
      "${dotfiles}/noctalia/.local/state/noctalia/settings.toml";

  home.packages = [ pkgs.kdePackages.breeze-icons ];

  xdg.configFile."qt6ct/qt6ct.conf".text = ''
    [Appearance]
    color_scheme_path=${config.xdg.configHome}/qt6ct/colors/noctalia.conf
    custom_palette=true
    icon_theme=breeze-dark
    style=Fusion
  '';
}
