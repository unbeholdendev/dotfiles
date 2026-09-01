vim.g.mapleader = " "

require("config.options")

vim.pack.add({
  "https://github.com/ellisonleao/gruvbox.nvim",
  "https://github.com/ibhagwan/fzf-lua",
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/stevearc/oil.nvim",
})

vim.cmd.colorscheme("gruvbox")

require("oil").setup({ view_options = { show_hidden = true } })
require("config.keymaps")

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "astro", "css", "html", "javascript", "json", "typescript", "typescriptreact" },
  callback = function(ev) vim.treesitter.start(ev.buf) end,
})

vim.lsp.enable({
  "astro",
  "bashls",
  "cssls",
  "html",
  "jsonls",
  "lua_ls",
  "nixd",
  "tailwindcss",
  "ts_ls",
})
