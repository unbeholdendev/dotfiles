{ config, dotfiles, lib, pkgs, ... }:
let
  treesitter = pkgs.vimPlugins.nvim-treesitter;
  languages = [
    "astro"
    "css"
    "html"
    "javascript"
    "json"
    "tsx"
    "typescript"
  ];

  treesitterWithParsers = pkgs.symlinkJoin {
    name = "nvim-treesitter-with-parsers";
    paths = [ treesitter "${treesitter}/runtime" ]
      ++ map (language: treesitter.grammarPlugins.${language}) languages;
  };
in
{
  home.packages = with pkgs; [
    astro-language-server
    bash-language-server
    fd
    lua-language-server
    neovim
    nixd
    ripgrep
    tailwindcss-language-server
    typescript-language-server
    vscode-langservers-extracted
  ];

  xdg.configFile = {
    "nvim/init.lua".source = ../nvim/.config/nvim/init.lua;
    "nvim/lua/config/keymaps.lua".source =
      ../nvim/.config/nvim/lua/config/keymaps.lua;
    "nvim/lua/config/options.lua".source =
      ../nvim/.config/nvim/lua/config/options.lua;
    "nvim/pack/nix/start/nvim-treesitter".source = treesitterWithParsers;
  }
  // lib.optionalAttrs (dotfiles != null) {
    "nvim/nvim-pack-lock.json".source =
      config.lib.file.mkOutOfStoreSymlink
        "${dotfiles}/nvim/.config/nvim/nvim-pack-lock.json";
  };
}
