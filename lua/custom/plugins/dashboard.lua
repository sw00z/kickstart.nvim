return {
  'nvimdev/dashboard-nvim',
  event = 'VimEnter',
  config = function()
    require('dashboard').setup {
      theme = 'hyper',
      shortcut_type = 'letter',
      shuffle_letter = true,
    }
  end,
  dependencies = { { 'nvim-tree/nvim-web-devicons' } },
}
