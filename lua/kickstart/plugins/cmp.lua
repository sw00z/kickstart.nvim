return {
  { -- Autocompletion
    'hrsh7th/nvim-cmp',
    event = { 'InsertEnter', 'CmdlineEnter' },
    dependencies = {
      -- Snippet Engine & its associated nvim-cmp source
      {
        'L3MON4D3/LuaSnip',
        build = (function()
          -- Build Step is needed for regex support in snippets.
          -- This step is not supported in many windows environments.
          -- Remove the below condition to re-enable on windows.
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
            return
          end
          return 'make install_jsregexp'
        end)(),
        dependencies = {
          -- `friendly-snippets` contains a variety of premade snippets.
          --    See the README about individual language/framework/plugin snippets:
          --    https://github.com/rafamadriz/friendly-snippets
          {
            'rafamadriz/friendly-snippets',
            config = function()
              require('luasnip.loaders.from_vscode').lazy_load()
            end,
          },
        },
      },
      'saadparwaiz1/cmp_luasnip',

      -- Adds other completion capabilities.
      --  nvim-cmp does not ship with all sources by default. They are split
      --  into multiple repos for maintenance purposes.
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-buffer', -- buffer-word source for `/` and `?` search
      'hrsh7th/cmp-cmdline', -- `:` command-line completion
      'hrsh7th/cmp-nvim-lsp-signature-help',
      'onsails/lspkind.nvim', -- kind icons + aligned menu formatting
      -- Registers the `copilot` cmp source + the prioritize comparator used in
      -- sorting. Configured in custom/plugins/copilot-cmp.lua; declared here so it
      -- lazy-loads with cmp (was eager at startup) and the coupling is explicit.
      'zbirenbaum/copilot-cmp',
      -- Go: completes BARE symbols from UNIMPORTED packages (type `Marshal` →
      -- json.Marshal + auto-import on confirm) — a class gopls's completeUnimported
      -- (prefix-qualified only) does not cover (gopls issue #58461). sqlite.lua
      -- caches the workspace/symbol index. Source is gated to `go` buffers below.
      -- Note: stdlib symbols appear only after one stdlib package is imported.
      'kkharji/sqlite.lua',
      'samiulsami/cmp-go-deep',
    },
    config = function()
      -- See `:help cmp`
      local cmp = require 'cmp'
      local types = require 'cmp.types'
      local luasnip = require 'luasnip'
      local lspkind = require 'lspkind'
      luasnip.config.setup {}

      -- True when a non-space char sits left of the cursor (or we're in the
      -- command line). Gates <Tab>: complete after a word, otherwise indent.
      local has_words_before = function()
        if string.match(vim.fn.mode(), '^c') then
          return true
        end
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        local text = vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]
        return col ~= 0 and text:sub(col, col):match '%s' == nil
      end

      -- Emmet items are excluded from the normal LSP menu and only shown by <M-e>,
      -- so html/ts_ls completions are never mixed with abbreviation expansions.
      local function is_emmet(entry)
        local client = entry.source.source and entry.source.source.client
        return entry.source.name == 'nvim_lsp' and client ~= nil and client.name == 'emmet_language_server'
      end

      -- Selection and confirmation are separate to avoid accidental edits.
      local mapping = {
        -- Emmet-only menu: expand the abbreviation left of the cursor.
        ['<M-e>'] = cmp.mapping(function()
          cmp.complete { config = { sources = { { name = 'nvim_lsp', entry_filter = is_emmet } } } }
        end, { 'i' }),
        ['<Tab>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item { behavior = types.cmp.SelectBehavior.Select }
          elseif has_words_before() then
            cmp.complete()
          else
            fallback()
          end
        end, { 'i', 'c' }),
        -- <S-Tab>: previous item, or open the menu on an empty line.
        ['<S-Tab>'] = cmp.mapping(function()
          if cmp.visible() then
            cmp.select_prev_item { behavior = types.cmp.SelectBehavior.Select }
          else
            cmp.complete()
          end
        end, { 'i', 'c' }),
        -- Vim-style up/down through the menu.
        ['<C-j>'] = cmp.mapping(cmp.mapping.select_next_item { behavior = types.cmp.SelectBehavior.Select }, { 'i', 'c' }),
        ['<C-k>'] = cmp.mapping(cmp.mapping.select_prev_item { behavior = types.cmp.SelectBehavior.Select }, { 'i', 'c' }),
        -- Confirm only a genuinely selected item; otherwise pass <CR> through.
        ['<CR>'] = cmp.mapping(function(fallback)
          if not cmp.confirm { select = false } then
            fallback()
          end
        end, { 'i', 'c' }),
        -- Dismiss the menu (or pass through when it's already closed).
        ['<C-e>'] = cmp.mapping(function(fallback)
          if not cmp.abort() then
            fallback()
          end
        end, { 'i', 'c' }),
        -- Scroll the documentation window. Insert-only so cmdline <C-u> keeps
        -- its native "clear line"; scroll_docs falls through when no doc is shown.
        ['<C-d>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i' }),
        ['<C-u>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i' }),
        -- Manual trigger.
        ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
        -- Snippet placeholder jumps — deliberately NOT on <Tab> (not Super-Tab).
        ['<C-l>'] = cmp.mapping(function()
          if luasnip.expand_or_locally_jumpable() then
            luasnip.expand_or_jump()
          end
        end, { 'i', 's' }),
        ['<C-h>'] = cmp.mapping(function()
          if luasnip.locally_jumpable(-1) then
            luasnip.jump(-1)
          end
        end, { 'i', 's' }),
      }

      -- CompletionItemKind name -> short uppercase tag shown in the `kind` column.
      local kind_abbr = {
        Text = 'TEXT',
        Method = 'METH',
        Function = 'FUNC',
        Constructor = 'CTOR',
        Field = 'FLD',
        Variable = 'VAR',
        Class = 'CLS',
        Interface = 'IFCE',
        Module = 'MOD',
        Property = 'PROP',
        Unit = 'UNIT',
        Value = 'VAL',
        Enum = 'ENUM',
        Keyword = 'KW',
        Snippet = 'SNPT',
        Color = 'CLR',
        File = 'FILE',
        Reference = 'REF',
        Folder = 'DIR',
        EnumMember = 'EMEM',
        Constant = 'CNST',
        Struct = 'STRC',
        Event = 'EVNT',
        Operator = 'OP',
        TypeParameter = 'TYPE',
        Copilot = 'CPLT',
      }
      -- cmp source id -> bracketed tag shown furthest right in the `menu` column.
      local source_tag = {
        nvim_lsp = '[LSP]',
        luasnip = '[Snip]',
        path = '[Path]',
        copilot = '[Copilot]',
        lazydev = '[Dev]',
        nvim_lsp_signature_help = '[Sig]',
        buffer = '[Buf]',
        go_deep = '[Go]',
        clangd_overloads = '[C++]',
      }

      -- Comparator chain, shared by the global config and the per-filetype
      -- overrides below. `score_fn` replaces cmp's own score comparator when a
      -- server supplies a better ranking of its own (see the clangd block).
      local function comparators(score_fn)
        local c = {
          function(a, b)
            local ai, bi = a.source.name == 'copilot', b.source.name == 'copilot'
            if ai ~= bi then
              return not ai
            end
          end,
          cmp.config.compare.offset,
          cmp.config.compare.exact,
          score_fn or cmp.config.compare.score,
          cmp.config.compare.recently_used,
          cmp.config.compare.kind,
          cmp.config.compare.sort_text,
          cmp.config.compare.length,
          cmp.config.compare.order,
        }
        return c
      end

      cmp.setup {
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        completion = { completeopt = 'menu,menuone,noselect', autocomplete = { types.cmp.TriggerEvent.TextChanged } },
        matching = {
          disallow_fuzzy_matching = false,
          disallow_fullfuzzy_matching = false,
          disallow_partial_fuzzy_matching = false,
          disallow_partial_matching = false,
          disallow_prefix_unmatching = false,
        },
        -- Nothing pre-highlighted; first <Tab> opens the menu as a hint (cmp#1809).
        preselect = cmp.PreselectMode.None,
        -- Bordered, visually distinct menu vs. documentation surfaces. winhighlight
        -- links to semantic groups only (no hex) so it tracks every colorscheme;
        -- the borders delineate the two windows even on transparent-NormalFloat schemes.
        window = {
          completion = cmp.config.window.bordered {
            border = 'rounded',
            winhighlight = 'Normal:CmpNormal,FloatBorder:CmpBorder,CursorLine:CmpSel,Search:None',
            scrollbar = true,
            side_padding = 1,
          },
          -- bordered() drops max_width/max_height; merge them in so the doc window
          -- is actually capped (else cmp falls back to a screen-proportional size).
          documentation = vim.tbl_extend(
            'force',
            cmp.config.window.bordered {
              border = 'rounded',
              winhighlight = 'Normal:CmpDocNormal,FloatBorder:CmpDocBorder',
              scrollbar = true,
            },
            { max_width = 80, max_height = 20 }
          ),
        },
        -- Columns: label · <icon> KIND · [source]. The glyph + short uppercase
        -- kind tag sit to the right of the word; the source tag furthest right.
        formatting = {
          fields = { 'abbr', 'kind', 'menu' },
          format = function(entry, item)
            local kind_name = item.kind -- original CompletionItemKind name
            -- Truncate the label by display chars (UTF-8 safe) so a long
            -- signature never pushes the kind/source columns off-screen.
            -- 80, not 50: a C++ overload set only differs late in the signature
            -- ("print(FILE *stream, format_string<…" vs "print(format_string<…"),
            -- so a short cut renders every overload as the same visible row.
            if vim.fn.strchars(item.abbr) > 80 then
              item.abbr = vim.fn.strcharpart(item.abbr, 0, 79) .. '…'
            end
            -- kind_hl_group stays cmp's per-kind CmpItemKind<Kind>, so this
            -- glyph+tag is colored by category (see cmp_highlights below).
            item.kind = string.format('%s %s', lspkind.symbol_map[kind_name] or '', kind_abbr[kind_name] or kind_name:upper())
            item.menu = is_emmet(entry) and '[Emmet]' or source_tag[entry.source.name] or ''
            return item
          end,
        },
        sorting = {
          -- priority_weight + the copilot prioritizer float copilot suggestions
          -- above nvim-lsp (which would otherwise bury them).
          priority_weight = 2,
          comparators = comparators(),
        },
        mapping = mapping,
        sources = cmp.config.sources {
          {
            name = 'lazydev',
            -- set group index to 0 to skip loading LuaLS completions as lazydev recommends it
            group_index = 1,
          },
          {
            name = 'nvim_lsp',
            entry_filter = function(entry)
              return not is_emmet(entry)
            end,
          },
          { name = 'luasnip' },
          { name = 'path' },
          { name = 'nvim_lsp_signature_help' },
          { name = 'copilot' },
        },
      }

      -- `:` command-line completion reuses the shell-like <Tab> (paths, then commands).
      cmp.setup.cmdline(':', {
        mapping = mapping,
        sources = cmp.config.sources({ { name = 'path' } }, { { name = 'cmdline' } }),
      })
      -- `/` and `?` search: buffer words matched as EXACT contiguous substrings
      -- (case-insensitive). The permissive matcher keeps every candidate; the
      -- entry_filter narrows to literal substrings — so `add` finds `yADDy` and
      -- `paddle`, never the gapped `yArDDy` (which cmp's flags alone can't reject).
      cmp.setup.cmdline({ '/', '?' }, {
        mapping = mapping,
        matching = {
          disallow_fuzzy_matching = false,
          disallow_fullfuzzy_matching = false,
          disallow_partial_fuzzy_matching = false,
          disallow_partial_matching = false,
          disallow_prefix_unmatching = false,
        },
        sources = {
          {
            name = 'buffer',
            entry_filter = function(entry, ctx)
              local query = ctx.cursor_before_line:sub(entry:get_offset())
              return query == '' or entry:get_word():lower():find(query:lower(), 1, true) ~= nil
            end,
          },
        },
      })

      -- Go: register cmp-go-deep and layer it onto the normal sources for `go`
      -- buffers only. The plugin has no setup() — options pass through the cmp
      -- source's `option` field (params.option).
      -- keyword_length/max_item_count cap the source; regex doc/package impls avoid
      -- an extra hover RPC per item. pcall-guarded so a load failure can't take
      -- down go completion entirely.
      local ok_godeep, godeep_error = pcall(function()
        cmp.register_source('go_deep', require('cmp_go_deep').new())
      end)
      if ok_godeep then
        cmp.setup.filetype('go', {
          sources = cmp.config.sources {
            { name = 'nvim_lsp' },
            {
              name = 'go_deep',
              keyword_length = 3,
              max_item_count = 5,
              option = {
                get_documentation_implementation = 'regex',
                get_package_name_implementation = 'regex',
                exclude_internal_packages = true,
                debounce_gopls_requests_ms = 250,
              },
            },
            { name = 'luasnip' },
            { name = 'path' },
            { name = 'nvim_lsp_signature_help' },
            { name = 'copilot' },
          },
        })
      else
        vim.notify('Go completion source unavailable: ' .. tostring(godeep_error), vim.log.levels.WARN)
      end

      -- C/C++: swap nvim_lsp for the clangd wrapper that collapses an overload set
      -- into one row and lists every signature in the documentation window (see
      -- custom/cmp_clangd_overloads.lua; it delegates to cmp-nvim-lsp's own source,
      -- so behaviour is otherwise identical). pcall-guarded so a load failure leaves
      -- C/C++ completion working rather than dead.
      local ok_clangd, clangd_error = pcall(function()
        cmp.register_source('clangd_overloads', require('custom.cmp_clangd_overloads').new())
      end)
      if ok_clangd then
        -- clangd ranks its own candidates and ships the result as `score` on each
        -- item; cmp discards it by default and re-ranks with generic heuristics.
        -- This comparator multiplies clangd's score by cmp's, and falls back to
        -- cmp's alone when an item carries none (index-based results do not), so
        -- it is a strict refinement of the default ordering rather than a swap.
        local ok_scores, clangd_score = pcall(require, 'clangd_extensions.cmp_scores')
        cmp.setup.filetype({ 'c', 'cpp' }, {
          sorting = { priority_weight = 2, comparators = comparators(ok_scores and clangd_score or nil) },
          sources = cmp.config.sources {
            { name = 'clangd_overloads' },
            {
              name = 'nvim_lsp',
              entry_filter = function(entry)
                local source = entry.source.source
                return not source or not source.client or source.client.name ~= 'clangd'
              end,
            },
            { name = 'luasnip' },
            { name = 'path' },
            { name = 'nvim_lsp_signature_help' },
            { name = 'copilot' },
          },
        })
      else
        vim.notify('C++ grouping unavailable; using native completions: ' .. tostring(clangd_error), vim.log.levels.WARN)
      end

      -- Dedicated dark palette for the cmp menus, applied with fixed colors (no
      -- default=) so the popups stay dark on every colorscheme. Re-applied on
      -- ColorScheme since loading a scheme reissues all highlights.
      local function cmp_highlights()
        local set = vim.api.nvim_set_hl
        -- Window chrome: near-black bg, subtle grey border, visible selection row.
        set(0, 'CmpNormal', { bg = '#0e0f13', fg = '#cdd0d6' })
        set(0, 'CmpBorder', { bg = '#0e0f13', fg = '#34373f' })
        set(0, 'CmpDocNormal', { bg = '#0a0b0e', fg = '#b6bac2' })
        set(0, 'CmpDocBorder', { bg = '#0a0b0e', fg = '#34373f' })
        set(0, 'CmpSel', { bg = '#2a2e37', bold = true })
        -- Scrollbar, kept dark to match the menu.
        set(0, 'PmenuThumb', { bg = '#4a4d55' })
        set(0, 'PmenuSbar', { bg = '#16171b' })
        -- Label column: normal text, matched chars pop blue, deprecated struck out.
        set(0, 'CmpItemAbbr', { fg = '#cdd0d6' })
        set(0, 'CmpItemAbbrMatch', { fg = '#7aa2f7', bold = true })
        set(0, 'CmpItemAbbrMatchFuzzy', { link = 'CmpItemAbbrMatch' })
        set(0, 'CmpItemAbbrDeprecated', { fg = '#6b7280', strikethrough = true })
        -- Source tag furthest right, most muted.
        set(0, 'CmpItemMenu', { fg = '#5c6370', italic = true })
        set(0, 'LspSignatureActiveParameter', { fg = '#7aa2f7', bold = true, underline = true })
        -- <icon> KIND tag, colored per category (types / callables / data / …).
        set(0, 'CmpItemKind', { fg = '#828a99' }) -- fallback for kinds not listed
        local kind_colors = {
          ['#e0af68'] = { 'Class', 'Struct', 'Interface', 'Enum', 'TypeParameter' },
          ['#7aa2f7'] = { 'Function', 'Method', 'Constructor', 'Event', 'Operator' },
          ['#bb9af7'] = { 'Variable', 'Field', 'Property', 'EnumMember' },
          ['#f7768e'] = { 'Keyword', 'Reference' },
          ['#9ece6a'] = { 'Snippet' },
          ['#7dcfff'] = { 'Text', 'Constant', 'Value', 'Unit', 'Color', 'File', 'Folder', 'Module', 'Copilot' },
        }
        for color, kinds in pairs(kind_colors) do
          for _, k in ipairs(kinds) do
            set(0, 'CmpItemKind' .. k, { fg = color })
          end
        end
      end
      cmp_highlights()
      vim.api.nvim_create_autocmd('ColorScheme', { callback = cmp_highlights })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
