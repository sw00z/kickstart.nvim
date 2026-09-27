-- LSP Plugins
return {
  {
    -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
    -- used for completion, annotations and signatures of Neovim apis
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
  {
    -- Main LSP Configuration
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for Neovim
      -- Mason must be loaded before its dependents so we need to set it up here.
      -- PATH = 'append': project-local binaries (mise shims) win over Mason;
      -- Mason stays the fallback when no per-project pin exists.
      { 'williamboman/mason.nvim', opts = { PATH = 'append' } },
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',

      -- Useful status updates for LSP.
      { 'j-hui/fidget.nvim', opts = {} },

      -- Allows extra capabilities provided by nvim-cmp
      'hrsh7th/cmp-nvim-lsp',
      -- 'hrsh7th/cmp-buffer',
      -- 'hrsh7th/cmp-cmdline',

      -- JSON/YAML schema catalog for auto-completion in config files
      'b0o/schemastore.nvim',
    },
    config = function()
      require('custom.lsp_profiles').setup()
      require('custom.lsp_attach').setup()
      require('custom.lsp_tools').setup()
      require('custom.lang_docs').setup()
      -- Every LSP float — hover, signature help, diagnostics — inherits the
      -- global NormalFloat, and open_floating_preview exposes no option to
      -- override it. Fifteen themes here leave NormalFloat with no bg (all
      -- twelve noirbuddy variants, plus mellow, nordic, oxocarbon and flow),
      -- which makes a hover composite over the buffer text beneath it. Wrapping
      -- the one function they all route through keeps that transparency
      -- everywhere it is deliberate — telescope, edgy, cmp, which-key — and
      -- drops it only where documentation has to be read. LspFloat* are defined
      -- per-colorscheme in custom/theme_readability.lua.
      local open_floating_preview = vim.lsp.util.open_floating_preview
      vim.lsp.util.open_floating_preview = function(...)
        local buf, win = open_floating_preview(...)
        if win and vim.api.nvim_win_is_valid(win) then
          vim.wo[win].winhighlight = 'NormalFloat:LspFloatNormal,FloatBorder:LspFloatBorder'
        end
        return buf, win
      end

      -- Brief aside: **What is LSP?**
      --
      -- LSP is an initialism you've probably heard, but might not understand what it is.
      --
      -- LSP stands for Language Server Protocol. It's a protocol that helps editors
      -- and language tooling communicate in a standardized fashion.
      --
      -- In general, you have a "server" which is some tool built to understand a particular
      -- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
      -- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
      -- processes that communicate with some "client" - in this case, Neovim!
      --
      -- LSP provides Neovim with features like:
      --  - Go to definition
      --  - Find references
      --  - Autocompletion
      --  - Symbol Search
      --  - and more!
      --
      -- Thus, Language Servers are external tools that must be installed separately from
      -- Neovim. This is where `mason` and related plugins come into play.
      --
      -- If you're wondering about lsp vs treesitter, you can check out the wonderfully
      -- and elegantly composed help section, `:help lsp-vs-treesitter`

      --  This function gets run when an LSP attaches to a particular buffer.
      --    That is to say, every time a new file is opened that is associated with
      --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
      --    function will be executed to configure the current buffer
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          -- NOTE: Remember that Lua is a real programming language, and as such it is possible
          -- to define small helper and utility functions so you don't have to repeat yourself.
          --
          -- In this case, we create a function that lets us more easily define mappings specific
          -- for LSP related items. It sets the mode, buffer and description for us each time.
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          -- Resolves a neovim 0.10/0.11 API difference; gates capability-specific
          -- keymaps and autocmds below so they only bind when the server supports them.
          ---@param c vim.lsp.Client
          ---@param method vim.lsp.protocol.Method
          ---@param bufnr? integer
          ---@return boolean
          local function client_supports_method(c, method, bufnr)
            if vim.fn.has 'nvim-0.11' == 1 then
              return c:supports_method(method, bufnr)
            else
              return c.supports_method(method, { bufnr = bufnr })
            end
          end

          -- Jump to the definition of the word under your cursor.
          --  This is where a variable was first declared, or where a function is defined, etc.
          --  To jump back, press <C-t>.
          map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')

          -- Capability-guarded: a server lacking the provider would otherwise get a
          -- rejected request and an empty/erroring picker the moment it attaches.
          -- Find references for the word under your cursor.
          if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_references, event.buf) then
            map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
          end

          -- Jump to the implementation of the word under your cursor.
          if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_implementation, event.buf) then
            map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
          end

          -- Jump to the *type* of the word under your cursor (not where it was defined).
          if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_typeDefinition, event.buf) then
            map('<leader>Lt', require('telescope.builtin').lsp_type_definitions, '[L]SP Type Definition')
          end

          -- Fuzzy find all the symbols in your current document.
          --  Symbols are things like variables, functions, types, etc.
          map('<leader>Ls', require('telescope.builtin').lsp_document_symbols, '[L]SP Document [S]ymbols')

          -- Fuzzy find all the symbols in your current workspace.
          --  Similar to document symbols, except searches over your entire project.
          map('<leader>Lw', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[L]SP [W]orkspace Symbols')

          -- Rename the variable under your cursor.
          --  Most Language Servers support renaming across files, etc.
          map('<leader>Ln', vim.lsp.buf.rename, '[L]SP Re[n]ame')

          -- Execute a code action, usually your cursor needs to be on top of an error
          -- or a suggestion from your LSP for this to activate. Routes through
          -- tiny-code-action (diff preview before apply); falls back to the native
          -- menu if that plugin is absent. Buffer-local, so it must call the plugin
          -- here — a global keymap in code-action-preview.lua would be shadowed.
          map('<leader>La', function()
            local ok, tca = pcall(require, 'tiny-code-action')
            if ok then
              tca.code_action()
            else
              vim.lsp.buf.code_action()
            end
          end, '[L]SP Code [A]ction', { 'n', 'x' })

          -- WARN: This is not Goto Definition, this is Goto Declaration.
          --  For example, in C this would take you to the header.
          map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          -- Hover (the method-info box). Bordered per-call to match cmp's windows,
          -- scoped here rather than via a global float border.
          map('K', function()
            vim.lsp.buf.hover { border = 'rounded' }
          end, 'Hover Documentation')

          -- Signature help in normal mode (shows function parameter info)
          map('gK', function()
            vim.lsp.buf.signature_help { border = 'rounded' }
          end, 'Signature Help')

          -- Diagnostic navigation
          map('[d', function()
            vim.diagnostic.jump { count = -1 }
          end, 'Previous Diagnostic')
          map(']d', function()
            vim.diagnostic.jump { count = 1 }
          end, 'Next Diagnostic')
          map('[e', function()
            vim.diagnostic.jump { count = -1, severity = vim.diagnostic.severity.ERROR }
          end, 'Previous Error')
          map(']e', function()
            vim.diagnostic.jump { count = 1, severity = vim.diagnostic.severity.ERROR }
          end, 'Next Error')
          map('gl', vim.diagnostic.open_float, 'Line Diagnostics')

          -- Documentation motions that hover and completion can't serve: Ld
          -- browses the library docs for the symbol under the cursor (gopls'
          -- own viewer for Go, the DevDocs docset elsewhere), Le opens whatever
          -- an import pulls in and outlines its symbols. See custom/lang_docs.lua.
          map('<leader>Ld', function()
            require('custom.lang_docs').browse()
          end, '[L]SP Browse [d]ocs for symbol')
          map('<leader>Le', function()
            require('custom.lang_docs').explore()
          end, '[L]SP [E]xplore import (open + outline)')
          map('<leader>LS', '<cmd>LspSource<cr>', 'Go to implementation source')
          map('<leader>LD', '<cmd>LibraryDocs<cr>', 'Installed library documentation')
          map('<leader>LP', function()
            vim.ui.select({ 'full', 'balanced', 'reset' }, { prompt = 'Project analysis profile' }, function(choice)
              if choice then
                vim.cmd('LspProfile ' .. choice)
              end
            end)
          end, 'Select project profile')
          map('<leader>LI', '<cmd>LspContext<cr>', 'Inspect language context')

          -- Workspace folder management
          map('<leader>LWa', vim.lsp.buf.add_workspace_folder, '[L]SP [W]orkspace [A]dd Folder')
          map('<leader>LWr', vim.lsp.buf.remove_workspace_folder, '[L]SP [W]orkspace [R]emove Folder')
          map('<leader>LWl', function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
          end, '[L]SP [W]orkspace [L]ist Folders')

          require('custom.lsp_attach').refresh(event.buf)
        end,
      })

      -- Inlay hints: defer to a colorscheme's own LspInlayHint when it sets one
      -- (rose-pine, catppuccin, nightfox, … style it per-theme). Neovim core only
      -- links LspInlayHint -> NonText, which is too dim to read, so we step in
      -- ONLY when the active theme left that default. The fg simulates opacity:
      -- main-grid virtual text can't be truly translucent (no compositor), so we
      -- blend the hint "ink" toward the theme's Normal bg by INLAY_OPACITY.
      -- Recomputed on ColorScheme so it tracks each theme's background.
      local INLAY_FG = 0xa0a6b0 -- hint "ink" before blending
      local INLAY_OPACITY = 0.5 -- 0 = invisible (all bg), 1 = full-strength ink
      -- Mix `fg` over `bg` by `ratio` (per channel); returns "#rrggbb".
      local function blend(fg, bg, ratio)
        local function ch(c)
          return math.floor(c / 65536) % 256, math.floor(c / 256) % 256, c % 256
        end
        local fr, fg2, fb = ch(fg)
        local br, bg2, bb = ch(bg)
        local function mix(a, b)
          return math.floor(a * ratio + b * (1 - ratio) + 0.5)
        end
        return string.format('#%02x%02x%02x', mix(fr, br), mix(fg2, bg2), mix(fb, bb))
      end
      local function inlay_hint_hl()
        local cur = vim.api.nvim_get_hl(0, { name = 'LspInlayHint' })
        if not (vim.tbl_isempty(cur) or cur.link == 'NonText') then
          return -- theme styles inlay hints itself; leave it alone
        end
        -- Transparent themes expose no Normal bg; assume a dark terminal.
        local bg = vim.api.nvim_get_hl(0, { name = 'Normal' }).bg or 0x1a1a1a
        vim.api.nvim_set_hl(0, 'LspInlayHint', { fg = blend(INLAY_FG, bg, INLAY_OPACITY) })
      end
      inlay_hint_hl()
      vim.api.nvim_create_autocmd('ColorScheme', { callback = inlay_hint_hl })

      -- Semantic-token layering. The server sends per-identifier kind/modifier
      -- facts (gopls: type nature + deprecated + defaultLibrary; rust_analyzer:
      -- mutable; …) that Treesitter's grammar-only view can't resolve, and Neovim
      -- paints them OVER Treesitter at priority 125. On themes that under-style the
      -- @lsp.* groups (most of this collection) the winning token group links to a
      -- bare, uncolored @lsp and flattens the richer Treesitter color. Dropping the
      -- band below Treesitter (100) inverts the order: Treesitter owns the base
      -- color wherever it has one, while tokens still surface where Treesitter is
      -- silent (Odin/Zig grammars are thin) and keep additive modifier attributes
      -- (strikethrough on deprecated, underline on mut). Ladder: syntax 50 ·
      -- treesitter 100 · semantic_tokens 125 · diagnostics 150.
      local hl = vim.hl or vim.highlight -- vim.hl since 0.10; alias kept for older
      hl.priorities.semantic_tokens = 95

      -- Diagnostic Config
      -- See :help vim.diagnostic.Opts
      vim.diagnostic.config {
        severity_sort = true,
        float = { border = 'rounded', source = 'if_many' },
        underline = { severity = vim.diagnostic.severity.ERROR },
        signs = vim.g.have_nerd_font and {
          text = {
            [vim.diagnostic.severity.ERROR] = '󰅚 ',
            [vim.diagnostic.severity.WARN] = '󰀪 ',
            [vim.diagnostic.severity.INFO] = '󰋽 ',
            [vim.diagnostic.severity.HINT] = '󰌶 ',
          },
        } or {},
      }

      -- LSP servers and clients are able to communicate to each other what features they support.
      --  By default, Neovim doesn't support everything that is in the LSP specification.
      --  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
      --  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

      -- Enable the following language servers
      --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
      --
      --  Add any additional override configuration in the following tables. Available keys are:
      --  - cmd (table): Override the default command used to start the server
      --  - filetypes (table): Override the default list of associated filetypes for the server
      --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
      --  - settings (table): Override the default settings passed when initializing the server.
      --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
      -- Inlay-hint keys for the TS/JS language server (identical for both filetypes).
      local ts_inlay_hints = {
        includeInlayParameterNameHints = 'all',
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      }

      local servers = {
        clangd = {
          cmd = {
            'clangd',
            '--background-index',
            '--clang-tidy',
            -- Check selection belongs to the project's .clang-tidy/.clangd.
            '--header-insertion=iwyu',
            '--header-insertion-decorators',
            -- Emit one item per overload, each carrying its full signature. They are
            -- collapsed back into a single row — with every signature listed in the
            -- documentation window — by custom/cmp_clangd_overloads.lua. The 'bundled'
            -- alternative collapses them server-side but discards the signatures, and
            -- clangd exposes them nowhere else (resolveProvider=false).
            '--completion-style=detailed',
            '--all-scopes-completion',
            -- Default caps completion at 100 items, which `--all-scopes-completion`
            -- exhausts on short prefixes in std::.
            '--limit-results=300',
            '--function-arg-placeholders',
            '--fallback-style=llvm',
            '--pch-storage=memory',
            '--enable-config', -- honor per-project `.clangd` config files
            -- Align analysis with the clang-21 C/C++ toolchain (Zig uses llvm21-assert via zls, not clangd).
            '--query-driver=/home/swooz/local/bin/clang*,/usr/bin/clang*-21,/usr/lib/llvm-21/bin/clang*',
            -- Indexing threads and their priority. 16 cores here, so half to the
            -- index; `low` beats the default `background` (idle-cores-only), which
            -- can leave the index unbuilt for minutes on a busy machine.
            '-j=8',
            '--background-index-priority=low',
            -- Resolve emplace/make_unique-style forwarding to the real constructor
            -- in hover and go-to-definition, at some extra parse cost.
            '--parse-forwarding-functions',
          },
          init_options = {
            usePlaceholders = true,
            completeUnimported = true,
            clangdFileStatus = true,
          },
          capabilities = {
            offsetEncoding = { 'utf-16' },
          },
        },
        gopls = {
          settings = {
            gopls = {
              gofumpt = true,
              staticcheck = true,
              usePlaceholders = true,
              -- Hover links point at gopls' own doc viewer (a local HTTP server
              -- it spawns on demand) instead of pkg.go.dev. It renders from
              -- GOROOT and the module cache, so it works offline and documents
              -- the exact versions in go.mod rather than latest-on-the-web.
              -- Neovim opens the link via its window/showDocument handler.
              linksInHover = 'gopls',
              semanticTokens = true, -- off by default; separates types/params/functions
              analyses = {
                unusedparams = true,
                shadow = true,
                nilness = true,
                unusedwrite = true,
                useany = true,
              },
              hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                compositeLiteralTypes = true, -- struct type before anonymous composite literals
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
                ignoredError = true, -- marks discarded error returns with `// ignore error`
              },
              -- CodeLens actions gopls offers above code (run/debug test, generate, tidy).
              codelenses = { generate = true, test = true, tidy = true, upgrade_dependency = true, run_govulncheck = true },
            },
          },
        },
        -- Python semantic server. Hover under completion load: 31-267 ms vs pyright's 236-897 ms.
        ty = {
          -- client.settings aliases this table before before_init runs; mutate it, never replace it.
          -- No `ty` key by default: an empty table encodes as a JSON array, which ty rejects.
          settings = {},
          -- ty prefers VIRTUAL_ENV over <root>/.venv, so a venv activated for another project would win.
          before_init = function(_, config)
            local active = vim.env.VIRTUAL_ENV
            local venv = config.root_dir and vim.fs.joinpath(config.root_dir, '.venv')
            if active and venv and vim.fs.normalize(active) ~= venv and vim.fn.executable(venv .. '/bin/python') == 1 then
              config.settings.ty = { configuration = { environment = { python = venv } } }
            end
          end,
        },
        -- Opt-in fallback (`:LspStart pyright`); excluded from automatic_enable below.
        pyright = {
          settings = {
            python = {
              analysis = {
                typeCheckingMode = 'basic',
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = 'openFilesOnly',
              },
            },
          },
        },
        rust_analyzer = {
          settings = {
            ['rust-analyzer'] = {
              cargo = {
                allFeatures = true,
                loadOutDirsFromCheck = true,
                buildScripts = { enable = true },
              },
              checkOnSave = { command = 'clippy' },
              procMacro = { enable = true },
              files = {
                excludeDirs = { '.direnv', '.git', '.github', 'node_modules', 'target', 'venv', '.venv' },
              },
              inlayHints = {
                closureReturnTypeHints = { enable = 'always' },
                lifetimeElisionHints = { enable = 'always' },
              },
              imports = {
                granularity = { group = 'module' },
                prefix = 'self',
              },
            },
          },
        },
        ols = {
          settings = {
            enable_inlay_hints = true,
            enable_semantic_tokens = true,
          },
        },
        zls = {
          -- Prefer the hand-installed 0.17-dev zls that matches zig 0.17 (Mason only
          -- ships 0.16); fall back to PATH/Mason if it's ever missing.
          cmd = { vim.fn.executable(vim.fn.expand '~/local/bin/zls') == 1 and vim.fn.expand '~/local/bin/zls' or 'zls' },
          settings = {
            zls = {
              zig_exe_path = '/home/swooz/local/zig-release/bin/zig', -- pin the zig zls drives
              enable_snippets = true,
              -- enable_inlay_hints was removed in zls 0.14; on/off is now the
              -- client's job (vim.lsp.inlay_hint.enable on LspAttach).
              inlay_hints_show_parameter_name = true, -- param names at call sites
              inlay_hints_show_variable_type_hints = true, -- var/const type hints
              inlay_hints_show_struct_literal_field_type = true, -- struct-literal field types
              inlay_hints_show_builtin = true,
              inlay_hints_exclude_single_argument = true,
              inlay_hints_hide_redundant_param_names = true,
              inlay_hints_hide_redundant_param_names_last_token = true,
              enable_build_on_save = true,
              warn_style = true,
            },
          },
        },
        bashls = {},
        dockerls = {},
        terraformls = {},
        jsonls = {
          settings = {
            json = {
              schemas = require('schemastore').json.schemas(),
              validate = { enable = true },
            },
          },
        },
        yamlls = {
          settings = {
            yaml = {
              schemaStore = { enable = false, url = '' },
              schemas = require('schemastore').yaml.schemas(),
              keyOrdering = false,
            },
          },
        },
        ansiblels = {},
        solidity_ls = {},

        -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
        --
        -- Some languages (like typescript) have entire language plugins that can be useful:
        --    https://github.com/pmizio/typescript-tools.nvim
        --
        -- But for many setups, the LSP (`ts_ls`) will work just fine
        ts_ls = {
          init_options = {
            preferences = {
              includeCompletionsForModuleExports = true,
              includeCompletionsForImportStatements = true,
              includeCompletionsWithInsertText = true,
              importModuleSpecifierPreference = 'shortest',
            },
          },
          settings = {
            typescript = {
              inlayHints = ts_inlay_hints,
            },
            javascript = {
              inlayHints = ts_inlay_hints,
            },
          },
          on_attach = function(client)
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end,
        },
        prismals = {},
        graphql = {},
        cssls = {
          settings = {
            css = { validate = true, lint = { unknownAtRules = 'ignore' } },
            scss = { validate = true, lint = { unknownAtRules = 'ignore' } },
          },
        },
        html = {
          on_attach = function(client)
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end,
        },
        -- Emmet abbreviation expansion (html>head>title^body, !, ul>li*3).
        -- html-lsp does not include it; VS Code ships Emmet as a separate extension.
        emmet_language_server = {
          filetypes = { 'html', 'css', 'scss', 'javascriptreact', 'typescriptreact', 'vue', 'svelte' },
        },
        eslint = {},
        lua_ls = {
          settings = {
            Lua = {
              completion = { callSnippet = 'Replace' },
              diagnostics = { disable = { 'missing-fields' } },
              hint = {
                enable = true,
                setType = true,
                paramName = 'Literal',
                paramType = true,
                arrayIndex = 'Disable',
              },
            },
          },
        },

        -- ── New languages (Phase 4) ────────────────────────────────────────
        sqls = {}, -- SQL: lighter than sqlls, autocomplete + go-to-def. Mason-installable.
        kotlin_language_server = {}, -- Kotlin: requires JDK 17+ on PATH. Mason-installable.
        -- Java: hover, completion, native auto-import, references, code actions.
        -- Requires JDK 17+ on PATH. Mason-installable. For per-project workspaces +
        -- debugging, the nvim-jdtls plugin is the upgrade path; this basic entry
        -- covers editing/navigation via mason-lspconfig auto-enable.
        jdtls = {},

        -- Swift / SwiftUI: deferred. sourcekit-lsp ships with the Swift
        -- toolchain (Mason cannot install it). To re-enable:
        --   1. Install Swift: swift.org or `brew install swift`
        --   2. Uncomment the block below
        --   3. Uncomment `sourcekit = true` in `non_mason_servers`
        -- sourcekit = {
        --   cmd = { 'sourcekit-lsp' },
        --   filetypes = { 'swift', 'objc', 'objcpp' },
        --   root_dir = require('lspconfig.util').root_pattern('Package.swift', '.git'),
        -- },
      }

      -- Ensure the servers and tools above are installed
      --
      -- To check the current status of installed tools and/or manually install
      -- other tools, you can run
      --    :Mason
      --
      -- You can press `g?` for help in this menu.
      --
      -- `mason` had to be setup earlier: to configure its options see the
      -- `dependencies` table for `nvim-lspconfig` above.
      --
      -- You can add other tools here that you want Mason to install
      -- for you, so that they are available from within Neovim.
      local ensure_installed = vim.tbl_keys(servers or {})
      -- Exclude LSPs that Mason cannot install (toolchain-bundled servers).
      -- Their entries in `servers` above still configure lspconfig; they just
      -- have to be installed via the system package manager.
      local non_mason_servers = {
        -- sourcekit = true, -- Swift LSP, deferred (see servers block above)
      }
      ensure_installed = vim.tbl_filter(function(name)
        return not non_mason_servers[name]
      end, ensure_installed)
      vim.list_extend(ensure_installed, {
        'stylua',
        'hadolint',
        'tflint',
        'vale',
        'golangci-lint',
        'goimports',
        'gofumpt',
        'ruff',
        -- cppcheck removed: mason-registry dropped it (no cross-platform
        -- pre-built binaries). clangd's --clang-tidy-checks now covers the
        -- same C/C++ static-analysis surface (clang-analyzer-* + bugprone-*).
        'prettierd',
        'shellcheck',
        'markdownlint',
        'taplo',
        -- Phase 4 additions
        'sqlfluff', -- SQL linter + formatter
        'sql-formatter', -- SQL formatter alternative
        'ktlint', -- Kotlin linter + formatter
        -- Build dependency for parsers that need generation (swift, etc.)
        'tree-sitter-cli',
      })
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      -- nvim-lspconfig v2 + mason-lspconfig v2 (Neovim 0.11) configure servers
      -- through vim.lsp.config()/vim.lsp.enable(), not the old mason-lspconfig
      -- `handlers` + lspconfig[name].setup() path (removed in v2). On v2 that old
      -- path is a silent no-op: every `settings` table here was dropped and
      -- servers ran on nvim-lspconfig defaults — which is why gopls/ts_ls emitted
      -- no inlay hints (theirs default to off and only turn on via settings).

      -- Broadcast cmp capabilities to every server.
      vim.lsp.config('*', { capabilities = capabilities })

      -- Deep-merge our overrides over each server's lsp/<name>.lua defaults.
      -- mason-lspconfig v2 ships no per-server config of its own, so these are
      -- the only customization and are never clobbered when auto-enable fires.
      for name, cfg in pairs(servers) do
        vim.lsp.config(name, require('custom.lsp_tools').configure(name, cfg))
      end

      require('mason-lspconfig').setup {
        ensure_installed = {}, -- mason-tool-installer drives installs
        -- Default-on: every Mason-installed server is enabled. Declared servers
        -- use our config above; the rest fall back to nvim-lspconfig defaults
        -- plus the shared capabilities. Excluded servers stay installed for `:LspStart`: K waits for
        -- every hover-capable client, and ruff lints through nvim-lint on save, not per keystroke.
        automatic_enable = { exclude = { 'pylsp', 'pyright', 'ruff' } },
      }

      -- Mason only auto-enables its own packages. System/toolchain-installed
      -- servers (sourcekit, …) aren't Mason packages, so enable them directly.
      for name, _ in pairs(non_mason_servers) do
        vim.lsp.enable(name)
      end
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
