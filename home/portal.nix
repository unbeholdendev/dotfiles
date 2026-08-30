{ ... }:
{
  # The file alone, and not xdg.portal: that installs the portal packages from
  # nixpkgs beside Fedora's, and a portal is reached over D-Bus, where two
  # implementations of one interface answer at random.
  xdg.configFile."xdg-desktop-portal/niri-portals.conf".source =
    ../portal/.config/xdg-desktop-portal/niri-portals.conf;
}
