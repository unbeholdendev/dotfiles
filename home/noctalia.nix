{ config, dotfiles, ... }:
{
  xdg.stateFile."noctalia/settings.toml".source =
    config.lib.file.mkOutOfStoreSymlink
      "${dotfiles}/noctalia/.local/state/noctalia/settings.toml";
}
