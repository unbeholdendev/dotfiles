{ config, ... }:
{
  # noctalia rewrites this file whenever a setting changes, and the store is
  # read only, so it stays in the clone and the link points out of the store.
  home.file.".local/state/noctalia/settings.toml".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/Documents/dotfiles/noctalia/.local/state/noctalia/settings.toml";
}
