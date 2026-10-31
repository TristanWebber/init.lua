local function github_source(repo)
  return 'https://github.com/' .. repo
end

  -- Miscellaneous plugins that don't require any configuration

  -- Git related plugins
vim.pack.add {github_source('tpope/vim-fugitive')}
vim.pack.add {github_source('tpope/vim-rhubarb')}

  -- Detect tabstop and shiftwidth automatically
vim.pack.add {github_source('tpope/vim-sleuth')}

-- Useful plugin to show you pending keybinds.
vim.pack.add {github_source('folke/which-key.nvim')}
require('which-key').setup {
  delay = 0,
  spec = {
   { '<leader>c', group = '[C]ode' },
   { '<leader>c_', hidden = true },
   { '<leader>d', group = '[D]ocument' },
   { '<leader>d_', hidden = true },
   { '<leader>g', group = '[G]it' },
   { '<leader>g_', hidden = true },
   { '<leader>h', group = 'Git [H]unk', mode = {'n', 'v'} },
   { '<leader>h_', hidden = true },
   { '<leader>r', group = '[R]ename' },
   { '<leader>r_', hidden = true },
   { '<leader>s', group = '[S]earch', mode = {'n', 'v'} },
   { '<leader>s_', hidden = true },
   { '<leader>t', group = '[T]oggle' },
   { '<leader>t_', hidden = true },
   { '<leader>w', group = '[W]orkspace' },
   { '<leader>w_', hidden = true },
   { '<leader>', group = 'VISUAL <leader>', mode = { 'v' } },
  }
}

-- Set lualine as statusline
vim.pack.add {github_source('nvim-lualine/lualine.nvim')}
require('lualine').setup {
  options = {
    icons_enabled = false,
    theme = 'onedark',
    component_separators = '|',
    section_separators = '',
  },
}

-- Add indentation guides even on blank lines
vim.pack.add {github_source('lukas-reineke/indent-blankline.nvim')}
require('ibl').setup {}

-- vim: ts=2 sts=2 sw=2 et
