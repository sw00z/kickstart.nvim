-- mkdnflow: markdown navigation + table/list mechanics. Works on any .md (no
-- Obsidian vault needed). Maps are buffer-local to markdown (mkdnflow scopes by
-- `filetypes`), which is exactly how the same physical key means different things
-- in prose vs code — switch to a .go file and these vanish, native keys return.
--
-- Design (per your request: don't clobber useful motions):
--   <CR>   follow / create link · toggle checkbox   (in NORMAL mode <CR> is a dead
--          motion — just "down a line" — so claiming it costs nothing)
--   <BS>   go back            ]l / [l   next / prev link
--   <Tab>/<S-Tab>   next/prev table cell — INSERT mode only (clobbers no motion)
--   <leader>M…   table + list edits (a couple keys, shown in which-key)
-- Motion/edit keys (s S o O + - y…) are explicitly left unmapped → stay native.
--
-- render-markdown remains the sole RENDERER; mkdnflow's own conceal/highlight is
-- off so the two don't double-draw.
return {
  'jakewvincent/mkdnflow.nvim',
  ft = 'markdown',
  opts = {
    filetypes = { md = true, markdown = true },
    modules = {
      -- keep the useful engines, drop ones that overlap render-markdown / yaml
      bib = false,
      folds = false,
    },
    links = { conceal = false }, -- render-markdown owns link conceal
    to_do = { highlight = false }, -- render-markdown owns checkbox display
    mappings = {
      -- single-keypress, non-motion actions
      MkdnEnter = { { 'n', 'v' }, '<CR>' },
      MkdnGoBack = { 'n', '<BS>' },
      MkdnNextLink = { 'n', ']l' },
      MkdnPrevLink = { 'n', '[l' },
      -- <leader>M group: checkbox + list/table edits
      MkdnToggleToDo = { { 'n', 'v' }, '<leader>Mx' },
      MkdnUpdateNumbering = { 'n', '<leader>Mn' },
      MkdnTableFromSelection = { 'v', '<leader>Mt' }, -- make a table out of selected text
      MkdnTableNewRowBelow = { 'n', '<leader>Mr' },
      MkdnTableNewRowAbove = { 'n', '<leader>MR' },
      MkdnTableNewColAfter = { 'n', '<leader>Mc' },
      MkdnTableNewColBefore = { 'n', '<leader>MC' },
      -- Tables auto-align as you edit; the per-column alignment commands:
      MkdnTableAlignLeft = { 'n', '<leader>Ml' },
      MkdnTableAlignRight = { 'n', '<leader>Mp' }, -- (p)ush right
      -- Table cell nav: DISABLED. mkdnflow's default is insert-mode <Tab>/<S-Tab>,
      -- which would shadow cmp's <Tab> completion inside markdown buffers.
      MkdnTableNextCell = false,
      MkdnTablePrevCell = false,
      -- DISABLE motion-clobbering defaults so native keys survive in markdown
      MkdnNewListItemBelowInsert = false, -- keep native o
      MkdnNewListItemAboveInsert = false, -- keep native O
      MkdnIncreaseHeading = false, -- keep native +
      MkdnDecreaseHeading = false, -- keep native -
      MkdnYankAnchorLink = false,
      MkdnYankFileAnchorLink = false,
      MkdnDestroyLink = false,
      MkdnTagSpan = false,
      MkdnMoveSource = false,
      MkdnTableNextRow = false,
      MkdnTablePrevRow = false,
      MkdnFoldSection = false,
      MkdnUnfoldSection = false,
      MkdnTab = false,
      MkdnSTab = false,
      MkdnExtendList = false,
    },
  },
}
