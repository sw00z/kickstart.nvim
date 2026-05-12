-- Colorscheme collection
-- Active scheme loads eagerly; all others are lazy-loaded for Telescope picker access (<leader>sc)
return {
  -- ACTIVE COLORSCHEME
  {
    'wtfox/jellybeans.nvim',
    lazy = false,
    priority = 1000,
    opts = {},
    config = function()
      vim.cmd.colorscheme 'jellybeans'
    end,
  },

  -- LAZY-LOADED COLORSCHEMES (available via Telescope picker)
  {
    'rose-pine/neovim',
    name = 'rose-pine',
    lazy = true,
  },
  {
    'ramojus/mellifluous.nvim',
    lazy = true,
    opts = {
      mellifluous = {
        color_overrides = {
          dark = {
            bg = function(bg)
              return bg:darkened(8)
            end,
            colors = function(colors)
              return {
                main_keywords = '#e0e066',
                operators = colors.functions:saturated(8),
              }
            end,
          },
        },
      },
    },
  },
  {
    'DonJulve/NeoCyberVim',
    lazy = true,
    opts = {
      transparent = false,
      italics = {
        comments = true,
        keywords = true,
        functions = true,
        strings = true,
        variables = true,
      },
      overrides = {},
    },
  },
  {
    'blazkowolf/gruber-darker.nvim',
    lazy = true,
    opts = {
      bold = true,
      invert = {
        signs = false,
        tabline = false,
        visual = false,
      },
      italic = {
        strings = true,
        comments = true,
        operators = false,
        folds = true,
      },
      undercurl = true,
      underline = true,
    },
  },
  {
    'bakageddy/alduin.nvim',
    lazy = true,
    config = function()
      local alduin = require 'alduin'
      alduin.palette.bg = '#1a1410'
    end,
  },
  {
    'embark-theme/vim',
    lazy = true,
  },
  {
    'lunacookies/vim-colors-xcode',
    lazy = true,
    opts = { green_comments = 1, emph_funcs = 1 },
  },
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    lazy = true,
    opts = {
      flavour = 'macchiato',
    },
  },
  {
    'Iron-E/nvim-highlite',
    lazy = true,
    config = function()
      require('highlite').setup { generator = { plugins = { vim = false }, syntax = false } }
    end,
  },
  {
    'mellow-theme/mellow.nvim',
    lazy = true,
    config = function()
      vim.g.mellow_transparent = true
      vim.g.mellow_italic_functions = true
      vim.g.mellow_bold_variables = true
    end,
  },
  {
    'AlexvZyl/nordic.nvim',
    lazy = true,
    config = function()
      require('nordic').setup {
        bold_keywords = true,
        transparent = {
          bg = true,
          float = true,
        },
        bright_border = true,
        reduced_blue = false,
        telescope = {
          style = 'classic',
        },
        cursorline = {
          theme = 'light',
          blend = 0.55,
        },
      }
    end,
  },
  {
    '0xstepit/flow.nvim',
    lazy = true,
    tag = 'v2.0.1',
    opts = {
      theme = {
        contrast = 'high',
        transparent = 'true',
      },
      colors = {
        custom = {
          saturation = '90',
        },
      },
      ui = {
        borders = 'fluo',
        aggressive_spell = true,
      },
    },
  },
  {
    'Yazeed1s/oh-lucy.nvim',
    lazy = true,
  },
  {
    'zootedb0t/citruszest.nvim',
    lazy = true,
    config = function()
      require('citruszest').setup {
        option = {
          transparent = false,
          bold = true,
          italic = true,
        },
        style = {
          Constant = { fg = '#232323', bold = true },
        },
      }
    end,
  },
  {
    'maxmx03/fluoromachine.nvim',
    lazy = true,
    config = function()
      require('fluoromachine').setup {
        glow = true,
        bright_border = false,
        brightness = 0.03,
        theme = 'retrowave',
        transparent = false,
      }
    end,
  },
  {
    'jaredgorski/spacecamp',
    lazy = true,
  },
  {
    'diegoulloao/neofusion.nvim',
    lazy = true,
    config = function()
      require('neofusion').setup {}
    end,
  },
  {
    'EdenEast/nightfox.nvim',
    lazy = true,
  },
}
