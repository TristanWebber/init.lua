return {
  -- NOTE: This is where your plugins related to LSP can be installed.
  --  The configuration is done below. Search for lspconfig to find it below.
  -- LSP Configuration & Plugins
  'neovim/nvim-lspconfig',
  dependencies = {
    -- Automatically install LSPs to stdpath for neovim
    'williamboman/mason.nvim',
    'williamboman/mason-lspconfig.nvim',

    -- Useful status updates for LSP
    -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
    { 'j-hui/fidget.nvim', opts = {} },

    -- Additional lua configuration, makes nvim stuff amazing!
    'folke/neodev.nvim',
    -- Autocompletion
    'hrsh7th/nvim-cmp',
      -- Snippet Engine & its associated nvim-cmp source
    'L3MON4D3/LuaSnip',
    'saadparwaiz1/cmp_luasnip',

    -- Adds LSP completion capabilities
    'hrsh7th/cmp-nvim-lsp',

    -- Adds a number of user-friendly snippets
    'rafamadriz/friendly-snippets',
  },
  config = function()
    -- [[ Configure LSP ]]
    --  This function gets run when an LSP connects to a particular buffer.
    local on_attach = function(_, bufnr)
      -- NOTE: Remember that lua is a real programming language, and as such it is possible
      -- to define small helper and utility functions so you don't have to repeat yourself
      -- many times.
      --
      -- In this case, we create a function that lets us more easily define mappings specific
      -- for LSP related items. It sets the mode, buffer and description for us each time.
      local nmap = function(keys, func, desc)
        if desc then
          desc = 'LSP: ' .. desc
        end

        vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
      end

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

      -- Create a command `:Format` local to the LSP buffer
      vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
        vim.lsp.buf.format()
      end, { desc = 'Format current buffer with LSP' })
    end
    -- mason-lspconfig requires that these setup functions are called in this order
    -- before setting up the servers.
    require('mason').setup()
    require('mason-lspconfig').setup()

    -- Enable the following language servers
    --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
    --
    --  Add any additional override configuration in the following tables. They will be passed to
    --  the `settings` field of the server config. You must look up that documentation yourself.
    --
    --  If you want to override the default filetypes that your language server will attach to you can
    --  define the property 'filetypes' to the map in question.
    local servers = {
      clangd = {},
      cmake = {},
      -- jsonls = {},
      -- arduino_language_server = {}, -- TODO this one needs additional configuration like here: https://github.com/williamboman/nvim-lsp-installer/tree/main/lua/nvim-lsp-installer/servers/arduino_language_server. Chances are this is not worth the effort
      -- gopls = {},
      pyright = {},
      rust_analyzer = {},
      -- tsserver = {},
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

    -- Setup neovim lua configuration
    require('neodev').setup()

    -- nvim-cmp supports additional completion capabilities, so broadcast that to servers
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

    -- Ensure the servers above are installed
    local mason_lspconfig = require 'mason-lspconfig'

    mason_lspconfig.setup {
      ensure_installed = vim.tbl_keys(servers),
    }

    local embedded_env = {
      NONE = 1,
      PIO = 2,
      IDF = 3,
    }

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

    local function get_pio_mcu()
      local cwd = vim.loop.cwd()
      for line in io.lines(cwd .. "/compile_commands.json") do
          local mcu = line:match("/tools/sdk/([^/]+)")
          if mcu then
            return mcu
          end
      end
    end

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
            return {"clangd", "--background-index", "--query-driver=/home/tristan/.espressif/tools/riscv32-esp-elf/esp-13.2.0_20230928/riscv32-esp-elf/bin/riscv32-esp-elf-*"} --pio esp32c3
          end
          if mcu_type == "esp32s3" then
            return { "/home/tristan/.llvm-project-xtensa/llvm-project/build/bin/clangd", "--background-index", "--query-driver=/home/tristan/.platformio/packages/toolchain-xtensa-esp32s3/bin/xtensa-esp32s3-elf-g*" } --pio esp32s3
          end
        end
      end
    end

    mason_lspconfig.setup_handlers {
      function(server_name)
        if server_name ~= "clangd" then
          require('lspconfig')[server_name].setup {
            capabilities = capabilities,
            on_attach = on_attach,
            settings = servers[server_name],
            filetypes = (servers[server_name] or {}).filetypes,
          }
        else
            -- specific treatment of clangd for embedded projects
          local env = get_embedded_env()
          if env ~= embedded_env.NONE then
            require('lspconfig').clangd.setup {
              cmd = get_cmd(env),
              on_attach = function(client, bufnr)
                client.server_capabilities.signatureHelpProvider = false
                on_attach(client, bufnr)
              end,
              capabilities = capabilities,
            }
          end
          -- not an embedded project
          if env == embedded_env.NONE then
            require('lspconfig').clangd.setup {
              on_attach = function(client, bufnr)
                client.server_capabilities.signatureHelpProvider = false
                on_attach(client, bufnr)
              end,
              capabilities = capabilities,
            }
          end
        end
      end,
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
  end
}
