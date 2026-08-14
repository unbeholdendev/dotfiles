local o = vim.o

o.number = true
o.relativenumber = true
o.cursorline = true
o.signcolumn = "yes"
o.scrolloff = 8
o.sidescrolloff = 8

o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.softtabstop = 2
o.smartindent = true
o.shiftround = true
o.breakindent = true
o.linebreak = true

o.undofile = true
o.confirm = true
o.updatetime = 250

o.splitright = true
o.splitbelow = true
o.clipboard = "unnamedplus"
o.winborder = "rounded"

o.ignorecase = true
o.smartcase = true
o.infercase = true

o.list = true
o.listchars = "tab:» ,trail:·,nbsp:␣"
o.colorcolumn = "100"
o.virtualedit = "block"
o.laststatus = 3

o.autocomplete = true
o.autocompletedelay = 100
o.complete = ".,w,b,u,t,o"
o.completeopt = "menu,menuone,popup,fuzzy"
o.pumheight = 10
