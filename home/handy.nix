{ config, dotfiles, ... }:
{
  xdg.dataFile."com.pais.handy/settings_store.json".source =
    config.lib.file.mkOutOfStoreSymlink
      "${dotfiles}/handy/.local/share/com.pais.handy/settings_store.json";
}
