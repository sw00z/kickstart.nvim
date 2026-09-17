-- Code-action diff preview: shows the change a code action will make BEFORE you
-- apply it, replacing the native blind menu. The `vim` backend renders the diff
-- in-process (no external delta/difftastic subprocess), keeping it fast even on a
-- large organize-imports edit. Reuses the already-loaded snacks picker for the
-- chooser. Lazy on LspAttach; the actual <leader>La binding lives in lspconfig.lua
-- (buffer-local, so it must call this from there — a global keymap here would be
-- shadowed by the buffer-local LSP map).
return {
  'rachartier/tiny-code-action.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  event = 'LspAttach',
  opts = {
    backend = 'vim', -- in-process diff; NOT delta/difftastic (those shell out + lag)
    picker = 'snacks',
  },
}
