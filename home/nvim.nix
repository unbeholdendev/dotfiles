{ config, dotfiles, ... }:
{
  xdg.configFile."nvim/init.lua".source = ../nvim/.config/nvim/init.lua;
  xdg.configFile."nvim/lua/config/options.lua".source =
    ../nvim/.config/nvim/lua/config/options.lua;

  # nvim writes this itself, on every `vim.pack` update, so it cannot be a
  # store file. It is the record of which commit of each plugin is in use.
  xdg.configFile."nvim/nvim-pack-lock.json".source =
    config.lib.file.mkOutOfStoreSymlink
      "${dotfiles}/nvim/.config/nvim/nvim-pack-lock.json";
}
