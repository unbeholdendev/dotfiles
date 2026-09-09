{ config, dotfiles, ... }:
{
  # Not xdg.mimeApps: that file is in the store, and anything setting its own
  # default writes to it.
  xdg.configFile."mimeapps.list".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/xdg/.config/mimeapps.list";
}
