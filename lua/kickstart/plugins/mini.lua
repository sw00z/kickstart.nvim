return {
  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    config = function()
      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
      --  - ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup { n_lines = 500 }

      -- Surround handled by vim-surround (custom/plugins/surround.lua) for ys/cs/ds keymaps

      -- Smooth animations for cursor movement and scroll
      require('mini.animate').setup {
        cursor = { timing = require('mini.animate').gen_timing.linear { duration = 80, unit = 'total' } },
        scroll = { enable = false },
        resize = { enable = false },
        open = { enable = false },
        close = { enable = false },
      }

      -- Animated scope indicator for current indent level
      require('mini.indentscope').setup {
        symbol = '│',
        draw = {
          delay = 50,
          animation = require('mini.indentscope').gen_animation.linear { duration = 50, unit = 'total' },
        },
      }
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
