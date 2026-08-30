vim.g.mapleader = " "

require("config.options")

vim.pack.add({
  "https://github.com/ellisonleao/gruvbox.nvim",
  "https://github.com/ibhagwan/fzf-lua",
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/stevearc/oil.nvim",
})

vim.cmd.colorscheme("gruvbox")

require("oil").setup()
require("config.keymaps")

-- nvim-lspconfig carries the server definitions alone. This is what starts one,
-- when a file the server claims is opened.
vim.lsp.enable({ "bashls", "lua_ls", "nixd" })
