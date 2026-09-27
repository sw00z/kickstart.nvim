-- Aerial: a navigable symbol outline backed by treesitter + LSP.
--
-- Sits alongside plugins this config already runs, each with a distinct job:
--   dropbar.nvim  → winbar breadcrumbs  (where the cursor is in the tree)
--   trouble.nvim  → flat symbol list     (<leader>xs)
--   aerial.nvim   → persistent outline panel + symbol-kind fold selection
--   nvim-ufo      → the folds themselves (custom/plugins/ufo.lua)
--
-- Backends fall through treesitter → lsp → markdown → asciidoc → man, so the
-- outline populates in any buffer that has a parser or an attached server.

-- zc closes the innermost open fold on a line. A multi-line signature adds a fold that
-- starts on the symbol's first line, so close outward until the fold covers the symbol.
local function close_symbol_fold(lnum, end_lnum)
  local fn = vim.fn
  while fn.foldclosedend(lnum) < end_lnum do
    local covered = fn.foldclosedend(lnum)
    vim.cmd(('silent! %dfoldclose'):format(lnum))
    local start = fn.foldclosed(lnum)
    if start ~= lnum then
      -- start > 0: the close reached a fold that begins above the symbol, so undo it.
      if start > 0 then
        vim.cmd(('silent! %dfoldopen'):format(lnum))
      end
      return
    end
    if fn.foldclosedend(lnum) == covered then
      return
    end
  end
end

-- Aerial normalizes symbol kinds across languages, so one kind list selects the same
-- folds in Python, C++, Lua and TypeScript.
local callable_kinds = { Function = true, Method = true, Constructor = true }

local function fold_callables()
  -- aerial defers setup until its first command runs; sync_load runs it and attaches a backend.
  require('aerial').sync_load()
  local aerial_data = require 'aerial.data'
  -- The first symbol fetch is throttled onto the event loop, so wait for it.
  vim.wait(1000, function()
    return aerial_data.has_received_data()
  end, 20)
  local data = aerial_data.get()
  if not data then
    vim.notify('Aerial has no symbols for this buffer', vim.log.levels.WARN)
    return
  end
  local symbols = {}
  for _, item in data:iter { skip_hidden = false } do
    if callable_kinds[item.kind] then
      table.insert(symbols, item)
    end
  end
  vim.cmd 'silent! %foldopen!'
  -- flat_items is pre-order, so reverse order closes nested functions before their parents.
  for i = #symbols, 1, -1 do
    close_symbol_fold(symbols[i].lnum, symbols[i].end_lnum)
  end
end

return {
  'stevearc/aerial.nvim',
  -- aerial's default branch requires Neovim 0.12+ (its setup() early-returns and
  -- registers no commands on older versions — a silent failure). This config
  -- runs on Neovim 0.11 (nvim-treesitter master does not support 0.12), so pin
  -- aerial's maintained 0.11 branch.
  branch = 'nvim-0.11',
  dependencies = {
    'nvim-treesitter/nvim-treesitter', -- structural backend (works without LSP)
    'nvim-tree/nvim-web-devicons', -- kind icons in the tree
  },
  -- Load just after the UI paints so :AerialOpen exists when edgy opens its Outline slot.
  event = 'VeryLazy',
  keys = {
    { '<leader>vv', '<cmd>AerialToggle<CR>', desc = 'Toggle outline (Aerial)' },
    { '<leader>vn', '<cmd>AerialNavToggle<CR>', desc = 'Nav popup (Aerial)' },
    { '<leader>vz', fold_callables, desc = 'Fold function bodies (Aerial)' },
    {
      '<leader>vf',
      function()
        -- require() force-loads telescope via lazy; load_extension is idempotent.
        require('telescope').load_extension 'aerial'
        require('telescope').extensions.aerial.aerial()
      end,
      desc = 'Find symbol (Aerial + Telescope)',
    },
    { ']a', '<cmd>AerialNext<CR>', desc = 'Next symbol (Aerial)' },
    { '[a', '<cmd>AerialPrev<CR>', desc = 'Prev symbol (Aerial)' },
    { ']A', '<cmd>AerialNextUp<CR>', desc = 'Next parent symbol (Aerial)' },
    { '[A', '<cmd>AerialPrevUp<CR>', desc = 'Up to parent symbol (Aerial)' },
  },
  opts = {
    -- treesitter first (instant, parser-backed); lsp fills parserless filetypes;
    -- markdown/asciidoc/man for docs. Explicit so it matches the header comment
    -- and can't silently shift if the plugin default changes.
    backends = { 'treesitter', 'lsp', 'markdown', 'asciidoc', 'man' },

    -- Symbol kinds per filetype. `_` is the fallback for unlisted filetypes; it
    -- adds member-level symbols (Variable/Constant/Field/Property/EnumMember/…)
    -- so the outline reflects module-level state, not just callables and types.
    -- Python keeps the container-only set — in-function locals drown the structure.
    filter_kind = {
      ['_'] = {
        'Class',
        'Constructor',
        'Enum',
        'EnumMember',
        'Field',
        'Function',
        'Interface',
        'Method',
        'Module',
        'Namespace',
        'Package',
        'Property',
        'Struct',
        'Constant',
        'Variable',
      },
      python = {
        'Class',
        'Constructor',
        'Enum',
        'Function',
        'Interface',
        'Method',
        'Module',
        'Struct',
        'Constant',
      },
      markdown = false, -- headings only
    },
    layout = {
      default_direction = 'prefer_right',
      min_width = 25,
      resize_to_content = true,
    },
    show_guides = true, -- draw tree connector lines
    autojump = true, -- moving in the outline moves the file cursor live
    highlight_on_hover = true, -- hovering an outline row highlights its source line
    nav = { preview = true }, -- AerialNav popup shows a code preview
    lsp = { diagnostics_trigger_update = true }, -- refresh outline when diagnostics change

    -- attach_mode 'global': when the outline is open it follows whichever file
    -- is active in the main editor, so switching files updates it live. No
    -- open_automatic — edgy starts closed and opens the outline on demand via
    -- its pinned Outline slot (open = 'AerialOpen') when you press <leader>e.
    attach_mode = 'global',

    -- nvim-ufo owns folds and forces foldmethod=manual; 'auto' would hand manual
    -- buffers back to aerial's foldexpr. The link_* options need manage_folds.
    manage_folds = false,

    -- ── Window navigation inside the outline ──────────────────────────────
    -- aerial binds <C-j>/<C-k> buffer-locally (down_and_scroll/up_and_scroll),
    -- which shadows the global <C-j>/<C-k> window moves (vim-tmux-navigator in
    -- tmux, herdr-splits in herdr). Disable
    -- them (merged over aerial's defaults, so every other aerial keymap stays) so
    -- Ctrl-h/j/k/l moves between windows everywhere, while plain j/k still cycles
    -- outline items. keymap_util skips any binding whose rhs is false.
    keymaps = {
      ['<C-j>'] = false,
      ['<C-k>'] = false,
    },
  },
}
