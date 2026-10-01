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
  callback = function(ev) pcall(vim.treesitter.start, ev.buf) end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function() vim.hl.on_yank() end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(ev)
    if vim.bo[ev.buf].filetype ~= "gitcommit" then vim.cmd('silent! normal! g`"') end
  end,
})

vim.diagnostic.config({ virtual_text = true })

vim.lsp.enable({ "bashls", "lua_ls", "nixd" })

require("vim._core.ui2").enable({})
