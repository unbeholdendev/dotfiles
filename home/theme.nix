{ ... }:
{
  # color-scheme drives the settings portal; GTK3 does not read it, so it also
  # needs gtk-theme.
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    gtk-theme = "Adwaita-dark";
  };
}
