local function github_source(repo)
  return 'https://github.com/' .. repo
end

-- Install plugins
vim.pack.add {
  github_source('neovim/nvim-lspconfig'),
  github_source('mason-org/mason.nvim'),
  github_source('mason-org/mason-lspconfig.nvim'),
  github_source('j-hui/fidget.nvim'),
  github_source('folke/neodev.nvim'),

  github_source('hrsh7th/nvim-cmp'),
  github_source('L3MON4D3/LuaSnip'),
  github_source('saadparwaiz1/cmp_luasnip'),
  github_source('hrsh7th/cmp-nvim-lsp'),
  github_source('rafamadriz/friendly-snippets')
}

require('mason').setup()
require('fidget').setup()
require('neodev').setup()

-- Helper functions to assist clangd with x-compilers
local embedded_env = {
  NONE = 1,
  PIO = 2,
  IDF = 3,
}

-- Get the development platform environment
local function get_embedded_env()
  local cwd = vim.loop.cwd()
  local f_pio = io.open(cwd .. "/platformio.ini")
  if f_pio then
    io.close(f_pio)
    return embedded_env.PIO
  end
  local f_idf = io.open(cwd .. "/dependencies.lock", "r")
  if f_idf then
    io.close(f_idf)
    return embedded_env.IDF
  end
  return embedded_env.NONE
end

-- Determine the x-compiler platform if using esp-idf
local function get_idf_mcu()
  local cwd = vim.loop.cwd()
  for line in io.lines(cwd .. "/dependencies.lock") do
    if string.find(line, "target:") then
      local words = {}
      for word in line:gmatch("%w+") do
        words[#words+1] = word
      end
      return words[2]
    end
  end
end

-- Determine the x-compiler platform if using platformio
local function get_pio_mcu()
  local cwd = vim.loop.cwd()
  for line in io.lines(cwd .. "/compile_commands.json") do
      local mcu = line:match("/tools/sdk/([^/]+)")
      if mcu then
        return mcu
      end
  end
end

-- Determine the clangd driver to use based on the device
local function get_cmd(env_type)
  if env_type == embedded_env.IDF then
    local mcu_type = get_idf_mcu()
    if mcu_type == "esp32" then
      return { "clangd", "--background-index", "--query-driver=/home/tristan/.espressif/tools/xtensa-esp-elf/esp-13.2.0_20230928/xtensa-esp-elf/bin/xtensa-esp32-elf-*" } --esp-idf esp32
    end
    if mcu_type == "esp32c3" then
      return { "clangd", "--background-index", "--query-driver=/home/tristan/.espressif/tools/riscv32-esp-elf/esp-13.2.0_20230928/riscv32-esp-elf/bin/riscv32-esp-elf-*" } --esp-idf esp32c3
    end
    if mcu_type == "esp32s2" then
      return { "clangd", "--background-index", "--query-driver=/home/tristan/.espressif/tools/xtensa-esp-elf/esp-13.2.0_20230928/xtensa-esp-elf/bin/xtensa-esp32s2-elf-*" } --esp-idf esp32s3
    end
    if mcu_type == "esp32s3" then
      return { "clangd", "--background-index", "--query-driver=/home/tristan/.espressif/tools/xtensa-esp-elf/esp-13.2.0_20230928/xtensa-esp-elf/bin/xtensa-esp32s3-elf-*" } --esp-idf esp32s3
    end
    else if env_type == embedded_env.PIO then
      local mcu_type = get_pio_mcu()
      if mcu_type == "esp32" then
        return { "clangd", "--background-index", "--query-driver=/home/tristan/.platformio/packages/toolchain-xtensa-esp32/bin/xtensa-esp32-elf-*" } --pio esp32
      end
      if mcu_type == "esp32c3" then
        return {"/home/tristan/.llvm-project-xtensa/llvm-project/build/bin/clangd", "--background-index", "--query-driver=/home/tristan/.espressif/tools/riscv32-esp-elf/esp-13.2.0_20230928/riscv32-esp-elf/bin/riscv32-esp-elf-*"} --pio esp32c3
      end
      if mcu_type == "esp32s3" then
        return { "/home/tristan/.llvm-project-xtensa/llvm-project/build/bin/clangd", "--background-index", "--query-driver=/home/tristan/.platformio/packages/toolchain-xtensa-esp32s3/bin/xtensa-esp32s3-elf-g*" } --pio esp32s3
      end
    end
  end
end

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
  callback = function(event)
    local nmap = function(keys, func, desc)
      if desc then
        desc = 'LSP: ' .. desc
      end

      vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
    end --nmap

    nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
    nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

    nmap('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
    nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
    nmap('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
    nmap('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
    nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
    nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

    -- See `:help K` for why this keymap
    nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
    nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

    -- Lesser used LSP functionality
    nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
    nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
    nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
    nmap('<leader>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, '[W]orkspace [L]ist Folders')

    local client = vim.lsp.get_client_by_id(event.data.client_id)
    local bufnr = client.buf

    -- specific treatment of clangd for embedded projects
    if client.name == "clangd" then
      local env = get_embedded_env()
      if env ~= embedded_env.NONE then
        vim.lsp.config[client.name].cmd = get_cmd(env)
      end
    end -- clangd setup
  end --callback
})

local servers = {
  clangd = {},
  pyright = {},
  rust_analyzer = {},
  html = { filetypes = { 'html', 'twig', 'hbs'} },

  lua_ls = {
    Lua = {
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
      -- NOTE: toggle below to ignore Lua_LS's noisy `missing-fields` warnings
      -- diagnostics = { disable = { 'missing-fields' } },
    },
  },
}

-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

-- Ensure the servers above are installed
require('mason-lspconfig').setup {
  ensure_installed = vim.tbl_keys(servers or {}),
  automatic_installation = false,
  handlers = {
    function(server_name)
      local server = servers[server_name] or {}
      server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
      require('lspconfig')[server_name].setup(server)
    end,
  },
}

-- TW added to get the return type from a function on hover
vim.lsp.buf.hover()

-- [[ Configure nvim-cmp ]]
-- See `:help cmp`
local cmp = require 'cmp'
local luasnip = require 'luasnip'
require('luasnip.loaders.from_vscode').lazy_load()
luasnip.config.setup {}

cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  completion = {
    completeopt = 'menu,menuone,noinsert',
  },
  mapping = cmp.mapping.preset.insert {
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete {},
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_locally_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.locally_jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  },
}
