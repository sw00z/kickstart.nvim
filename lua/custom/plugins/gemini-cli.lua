return {
  'gutsavgupta/nvim-gemini-companion',

  enabled = false,
  dependencies = { 'nvim-lua/plenary.nvim' },
  event = 'VeryLazy',
  cmds = { 'gemini' },
  win = {
    preset = 'floating',
    width = 0.9,
    height = 0.9,
  },
  config = function()
    require('gemini').setup()
  end,
  keys = {
    { '<leader>agg', '<cmd>GeminiToggle<cr>', desc = 'Toggle Gemini sidebar' },
    { '<leader>agc', '<cmd>GeminiSwitchToCli<cr>', desc = 'Spawn or switch to AI session' },
    {
      '<leader>ags',
      function()
        vim.cmd 'normal! gv'
        vim.cmd "'<,'>GeminiSend"
      end,
      mode = { 'x' },
      desc = 'Send selection to AI',
    },
  },
}
