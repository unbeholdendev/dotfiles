{ ... }:
{
  # GTK3 does not read color-scheme, so gtk-theme is needed as well.
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    gtk-theme = "Adwaita-dark";
  };
}
