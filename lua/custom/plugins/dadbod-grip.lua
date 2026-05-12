return {
  'joryeugene/dadbod-grip.nvim',
  version = '*',
  cmd = {
    'Grip',
    'GripStart',
    'GripConnect',
    'GripSchema',
    'GripTables',
    'GripQuery',
    'GripHistory',
  },
  keys = {
    { '<leader>qc', '<cmd>GripConnect<cr>', desc = 'DB connect' },
    { '<leader>qg', '<cmd>Grip<cr>', desc = 'DB grid' },
    { '<leader>qt', '<cmd>GripTables<cr>', desc = 'DB tables' },
    { '<leader>qq', '<cmd>GripQuery<cr>', desc = 'DB query pad' },
    { '<leader>qs', '<cmd>GripSchema<cr>', desc = 'DB schema' },
    { '<leader>qh', '<cmd>GripHistory<cr>', desc = 'DB history' },
    { '<leader>qd', '<cmd>GripStart<cr>', desc = 'DB demo' },
  },
  opts = {},
}
