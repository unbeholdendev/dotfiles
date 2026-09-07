{ config, dotfiles, ... }:
{
  xdg.configFile."com.pais.handy/settings_store.json".source =
    config.lib.file.mkOutOfStoreSymlink
      "${dotfiles}/handy/.config/com.pais.handy/settings_store.json";
}
