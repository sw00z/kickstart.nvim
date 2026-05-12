return {
  'kndndrj/nvim-projector',
  dependencies = {
    -- required:
    'MunifTanjim/nui.nvim',
    -- optional extensions:
    'kndndrj/projector-neotest',
    'kndndrj/projector-dbee',
    -- dependencies of extensions:
    'nvim-neotest/neotest',
    'kndndrj/nvim-dbee',
  },
  keys = {
    {
      '<leader>jc',
      function()
        require('projector').continue()
      end,
      desc = 'Continue',
    },
    {
      '<leader>jo',
      function()
        require('projector').continue()
      end,
      desc = 'Open Dashboard',
    },
    {
      '<leader>jt',
      function()
        require('projector').toggle()
      end,
      desc = 'Toggle UI',
    },
    {
      '<leader>jn',
      function()
        require('projector').next()
      end,
      desc = 'Next config',
    },
    {
      '<leader>jp',
      function()
        require('projector').previous()
      end,
      desc = 'Previous config',
    },
    {
      '<leader>jr',
      function()
        require('projector').restart()
      end,
      desc = 'Restart',
    },
    {
      '<leader>jk',
      function()
        require('projector').kill()
      end,
      desc = 'Kill',
    },
  },
  config = function()
    require('projector').setup {
      outputs = {
        require('projector_dbee').OutputBuilder:new(),
        require('projector_neotest').OutputBuilder:new(),
      },
    }
  end,
}
