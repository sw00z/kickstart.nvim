-- Aerial: a navigable, foldable symbol outline backed by treesitter + LSP.
--
-- Sits alongside plugins this config already runs, each with a distinct job:
--   dropbar.nvim  → winbar breadcrumbs  (where the cursor is in the tree)
--   trouble.nvim  → flat symbol list     (<leader>xs)
--   aerial.nvim   → persistent outline panel + symbol-tree code folding
--
-- Backends fall through treesitter → lsp → markdown → asciidoc → man, so the
-- outline populates in any buffer that has a parser or an attached server.
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
  -- Load once, just after the UI paints. setup() with manage_folds = true then
  -- registers autocmds that arm folding on every supported buffer from here on,
  -- so folds work without first opening the panel.
  event = 'VeryLazy',
  keys = {
    { '<leader>vv', '<cmd>AerialToggle<CR>', desc = 'Toggle outline (Aerial)' },
    { '<leader>vn', '<cmd>AerialNavToggle<CR>', desc = 'Nav popup (Aerial)' },
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

    -- ── Code folding driven by the symbol tree ────────────────────────────
    -- manage_folds lets aerial own foldmethod/foldexpr for supported buffers;
    -- collapsing a node in the tree folds the matching code region.
    manage_folds = true,
    link_tree_to_folds = true, -- fold/expand in the tree  → fold/expand the code
    link_folds_to_tree = false, -- manual code folds do NOT reshape the tree

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
  config = function(_, opts)
    require('aerial').setup(opts)
    -- Open files fully expanded; aerial-managed folds are then closed/opened on
    -- demand with native za/zo/zc/zR/zM or directly from the outline panel.
    vim.opt.foldlevel = 99
    vim.opt.foldlevelstart = 99
  end,
}
