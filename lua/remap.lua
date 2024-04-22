-- [[ Basic Keymaps ]]

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- TW remaps to auto-close symbols
local function map(mode, l, r, opts)
  local options = { noremap = true }
  if opts then
    options = vim.tbl_extend("force", options, opts)
  end
  vim.keymap.set(mode, l, r, options)
end

--map('i', '[', '[]<left>')
--map('i', '{', '{}<left>')
map('i', '{<CR>', '{<CR>}<ESC>O')
map('i', '{;', '{<CR>};<ESC>O')
--map('i', '\'', '\'\'<left>')-- Finding this one a bit annoying - slows typing
--map('i', '"', '""<left>')-- Finding this one a bit annoying - slows typing
--map('i', '(', '()<left>')-- Finding this one a bit annoying - slows typing
--map('i', '<', '<><left>')-- Finding this one a bit annoying - PITA for comparisons

-- TW remap to use 'jk' instead of <ESC> to go from 'i' or 'v' to 'n' mode
map({ 'i', 'v' }, 'jk', '<ESC>')

-- TW remaps for navigation and editing
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "J", "mzJ`z")

vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")
