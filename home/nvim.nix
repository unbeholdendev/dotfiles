{ config, dotfiles, lib, pkgs, ... }:
{
  # `init.lua` and fzf-lua call these by name, so they belong beside the config
  # rather than in each profile that imports it.
  home.packages = with pkgs; [
    bash-language-server
    fd
    lua-language-server
    nixd
    ripgrep
  ];

  xdg.configFile = {
    "nvim/init.lua".source = ../nvim/.config/nvim/init.lua;
    "nvim/lua/config/keymaps.lua".source =
      ../nvim/.config/nvim/lua/config/keymaps.lua;
    "nvim/lua/config/options.lua".source =
      ../nvim/.config/nvim/lua/config/options.lua;
  }
  # nvim writes this itself, on every `vim.pack` update, so it cannot be a
  # store file. It is the record of which commit of each plugin is in use. A
  # container gets none: it is thrown away, and an update there must not dirty
  # the clone it was started from.
  // lib.optionalAttrs (dotfiles != null) {
    "nvim/nvim-pack-lock.json".source =
      config.lib.file.mkOutOfStoreSymlink
        "${dotfiles}/nvim/.config/nvim/nvim-pack-lock.json";
  };
}
