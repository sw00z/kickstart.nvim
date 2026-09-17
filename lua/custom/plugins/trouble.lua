return {
  'folke/trouble.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  cmd = 'Trouble',
  keys = {
    { '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', desc = 'Diagnostics (Trouble)' },
    { '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', desc = 'Buffer Diagnostics (Trouble)' },
    { '<leader>xs', '<cmd>Trouble symbols toggle focus=false<cr>', desc = 'Symbols (Trouble)' },
    { '<leader>xq', '<cmd>Trouble qflist toggle<cr>', desc = 'Quickfix List (Trouble)' },
    -- LSP views: references + call hierarchy as a previewable foldable tree
    -- (native incoming/outgoing_calls only dump to quickfix without preview).
    { '<leader>xr', '<cmd>Trouble lsp_references toggle<cr>', desc = 'LSP References (Trouble)' },
    { '<leader>xi', '<cmd>Trouble lsp_incoming_calls toggle<cr>', desc = 'Incoming Calls (Trouble)' },
    { '<leader>xo', '<cmd>Trouble lsp_outgoing_calls toggle<cr>', desc = 'Outgoing Calls (Trouble)' },
    { '<leader>xl', '<cmd>Trouble lsp toggle focus=false win.position=right<cr>', desc = 'LSP Defs/Refs/Impls (Trouble)' },
  },
  opts = {},
}
