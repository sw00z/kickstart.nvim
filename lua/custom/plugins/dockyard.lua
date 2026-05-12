return {
  'emrearmagan/dockyard.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'akinsho/toggleterm.nvim',
  },
  cmd = { 'Dockyard', 'DockyardFloat' },
  keys = {
    { '<leader>Dk', '<cmd>DockyardFloat<cr>', desc = '[D]ockyard (float)' },
    { '<leader>DK', '<cmd>Dockyard<cr>', desc = '[D]ockyard (fullscreen)' },
  },
  opts = {},
}
