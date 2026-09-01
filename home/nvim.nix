{ config, dotfiles, lib, pkgs, ... }:
{
  home.packages = with pkgs; [
    bash-language-server
    fd
    lua-language-server
    neovim
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
  // lib.optionalAttrs (dotfiles != null) {
    "nvim/nvim-pack-lock.json".source =
      config.lib.file.mkOutOfStoreSymlink
        "${dotfiles}/nvim/.config/nvim/nvim-pack-lock.json";
  };
}
