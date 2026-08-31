{ ... }:
{
  # Not xdg.portal: that adds nixpkgs' portals beside Fedora's, and two
  # answers to one D-Bus interface race.
  xdg.configFile."xdg-desktop-portal/niri-portals.conf".source =
    ../portal/.config/xdg-desktop-portal/niri-portals.conf;
}
