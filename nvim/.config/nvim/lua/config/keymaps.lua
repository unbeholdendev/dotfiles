local map = vim.keymap.set

map("n", "<leader>f", "<cmd>FzfLua files<cr>", { desc = "Files" })
map("n", "<leader>/", "<cmd>FzfLua live_grep<cr>", { desc = "Grep" })
map("n", "<leader>b", "<cmd>FzfLua buffers<cr>", { desc = "Buffers" })
map("n", "<leader>s", "<cmd>FzfLua lsp_document_symbols<cr>", { desc = "Symbols in file" })
map("n", "<leader>S", "<cmd>FzfLua lsp_live_workspace_symbols<cr>", { desc = "Symbols in project" })
map("n", "<leader>h", "<cmd>FzfLua helptags<cr>", { desc = "Help" })
map("n", "<leader>r", "<cmd>FzfLua resume<cr>", { desc = "Last picker" })

map("n", "-", "<cmd>Oil<cr>", { desc = "Parent directory" })
map("n", "<leader>e", "<cmd>NvimTreeFindFileToggle<cr>", { desc = "File tree" })
