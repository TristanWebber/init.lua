local function github_source(repo)
  return 'https://github.com/' .. repo
end

vim.pack.add {github_source('navarasu/onedark.nvim')}

vim.cmd.colorscheme 'onedark'

-- load before anything else
--  priority = 1000,

-- vim: ts=2 sts=2 sw=2 et
