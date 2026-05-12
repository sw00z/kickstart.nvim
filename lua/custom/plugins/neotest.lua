return {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-neotest/nvim-nio',
    'nvim-lua/plenary.nvim',
    'antoinemadec/FixCursorHold.nvim',
    'nvim-treesitter/nvim-treesitter',
    -- Adapters
    'nvim-neotest/neotest-python', -- pytest / unittest
    'fredrikaverpil/neotest-golang', -- go test
    'marilari88/neotest-vitest', -- vitest
    'haydenmeade/neotest-jest', -- jest
    'arthur944/neotest-bun', -- bun test
    'thenbe/neotest-playwright', -- playwright
    'llllvvuu/neotest-foundry', -- foundry (forge test)
    'TheSnakeWitcher/hardhat.nvim', -- hardhat
    'alfaix/neotest-gtest', -- c++ google test
    'rcasia/neotest-bash', -- bash (bats)
    'lawrence-laz/neotest-zig', -- zig test
  },
  keys = {
    {
      '<leader>tt',
      function()
        require('neotest').run.run()
      end,
      desc = 'Run nearest test',
    },
    {
      '<leader>tf',
      function()
        require('neotest').run.run(vim.fn.expand '%')
      end,
      desc = 'Run current file',
    },
    {
      '<leader>ts',
      function()
        require('neotest').summary.toggle()
      end,
      desc = 'Toggle summary',
    },
    {
      '<leader>to',
      function()
        require('neotest').output.open { enter = true }
      end,
      desc = 'Show output',
    },
    {
      '<leader>tp',
      function()
        require('neotest').output_panel.toggle()
      end,
      desc = 'Toggle output panel',
    },
    {
      '<leader>tq',
      function()
        require('neotest').run.stop()
      end,
      desc = 'Stop test',
    },
    {
      '<leader>td',
      function()
        require('neotest').run.run { strategy = 'dap' }
      end,
      desc = 'Debug nearest test',
    },
    {
      '<leader>tw',
      function()
        require('neotest').watch.toggle(vim.fn.expand '%')
      end,
      desc = 'Watch file',
    },
  },
  config = function()
    require('neotest').setup {
      adapters = {
        require 'neotest-python' {
          dap = { justMyCode = false },
        },
        require 'neotest-golang',
        require 'neotest-vitest',
        require 'neotest-jest' {
          jestCommand = 'npx jest',
        },
        require 'neotest-bun',
        require 'neotest-playwright'.adapter {
          options = {
            persist_project_selection = true,
            enable_dynamic_test_discovery = true,
          },
        },
        require 'neotest-foundry',
        require 'neotest-gtest',
        require 'neotest-bash',
        require 'neotest-zig',
      },
    }
  end,
}
