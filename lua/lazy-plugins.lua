-- [[ Configure and install plugins ]]
--
--  To check the current status of your plugins, run
--    :Lazy
--
--  You can press `?` in this menu for help. Use `:q` to close the window
--
--  To update plugins you can run
--    :Lazy update
--
-- NOTE: Here is where you install your plugins.
--

-- vim.g.base46_cache = vim.fn.stdpath 'data' .. '/base46_cache/'

require('lazy').setup({
  --
  --
  -- NOTE: Plugins can be added with a link (or for a github repo: 'owner/repo' link).
  --
  --
  'tpope/vim-dadbod', -- Database interaction
  'kristijanhusak/vim-dadbod-ui', -- UI for executing cmds & viewing tables
  -- 'kristijanhusak/vim-dadbod-completion', -- Autocompletion for queries
  'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically
  'nanotee/zoxide.vim', -- Easily cd into directories through rankings of usage
  { 'junegunn/fzf' }, -- fzf for usage within vim
  {
    'https://git.sr.ht/~whynothugo/lsp_lines.nvim',
    config = function()
      local lsp_lines = require 'lsp_lines'
      vim.keymap.set('n', '<leader>l', lsp_lines.toggle, { desc = 'Toggle LSP lines' })
    end,
  },
  -- 'christoomey/vim-tmux-navigator', -- Make
  'sindrets/diffview.nvim', -- Convenient Git diff viewer & merge tool
  --
  --
  --
  -- Colorschemes
  {
    'bakageddy/alduin.nvim',
    enabled = false,
    lazy = false,
    priority = 1000,
    config = function()
      local try = require 'alduin'
      try.palette.bg = '#1a1410'
      vim.cmd 'colorscheme alduin'
      -- vim.cmd 'highlight Comment guifg=#3b6541'
      -- "vim.cmd 'highlight Normal guibg=#1a1410'
      vim.o.termguicolors = true
      -- vim.o.background = 'dark'
    end,
  },
  {
    'embark-theme/vim',
    enabled = false,
    priority = 1000,
    lazy = false,
    config = function()
      vim.cmd 'colorscheme embark'
      vim.opt.background = 'dark'
    end,
  },
  {
    'lunacookies/vim-colors-xcode',
    enabled = false,
    lazy = false,
    opts = { green_comments = 1, emph_funcs = 1 },
    config = function()
      vim.opt.background = 'dark'
      vim.cmd.colorscheme 'xcodedarkhc'
    end,
  },
  {
    'catppuccin/nvim',
    lazy = false,
    priority = 1000,
    name = 'catppuccin',
    enabled = false,
    config = function()
      require('catppuccin').setup {
        flavour = 'macchiato', -- latte, frappe, macchiato, mocha
        -- background = {
        --   light = 'latte',
        --   dark = 'mocha',
        -- },
      }
      vim.cmd.colorscheme 'catppuccin-macchiato'
    end,
  },
  {
    'Iron-E/nvim-highlite',
    enabled = true,
    lazy = false,
    priority = math.huge,
    config = function(_, opts)
      -- OPTIONAL: setup the plugin. See "Configuration" for information
      require('highlite').setup { generator = { plugins = { vim = false }, syntax = false } }

      -- or one of the alternate colorschemes (see the "Built-in Colorschemes" section)
      vim.api.nvim_command 'colorscheme highlite'
    end,
  },
  {
    'mellow-theme/mellow.nvim',
    enabled = false,
    config = function()
      -- require('mellow').setup {
      --   opts = {
      --     mellow_italic_functions = true,
      --     mellow_bold_functions = true,
      --     mellow_highlight_overrides = { ['NormalNC'] = { link = 'Normal' } },
      --   },
      -- }
      vim.g.mellow_transparent = true

      vim.g.mellow_italic_functions = true
      -- vim.g.mellow_bold_functions = true

      vim.g.mellow_bold_variables = true
      -- Load the colorscheme
      vim.cmd.colorscheme 'mellow'
    end,
  },

  {
    'AlexvZyl/nordic.nvim',
    enabled = false,
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
      vim.cmd.colorscheme 'nordic'
    end,
  },
  {
    '0xstepit/flow.nvim',
    enabled = false,
    lazy = false,
    priority = 1000,
    tag = 'v2.0.1',
    opts = {
      theme = {
        contrast = 'high',
        transparent = 'true',
      },
      colors = {
        custom = {
          saturation = '90',
          -- light = '55',
        },
      },
      ui = {
        borders = 'fluo',
        aggressive_spell = true,
      },
    },
    config = function(_, opts)
      require('flow').setup(opts)
      vim.cmd 'colorscheme flow'
    end,
  },
  {
    'Yazeed1s/oh-lucy.nvim',
    enabled = false,
    lazy = false,
    config = function()
      vim.cmd.colorscheme 'oh-lucy'
    end,
  },
  {
    'zootedb0t/citruszest.nvim',
    enabled = false,
    lazy = false,
    priority = 1000,
    config = function()
      -- For using default config leave thisempty.
      require('citruszest').setup {
        option = {
          transparent = false, -- Enable/Disable transparency
          bold = true,
          italic = true,
        },
        -- Override default highlight style in this table
        -- E.g If you want to override `Constant` highlight style
        style = {
          -- This will change Constant foreground color and make it bold.
          Constant = { fg = '#232323', bold = true },
        },
      }
      vim.cmd.colorscheme 'citruszest'
    end,
  },
  {
    'maxmx03/fluoromachine.nvim',
    enabled = false,
    lazy = false,
    priority = 1000,
    config = function()
      local fm = require 'fluoromachine'

      fm.setup {
        glow = true,
        bright_border = false,
        brightness = 0.03,
        theme = 'retrowave',
        transparent = false,
        -- overrides = {
        --   ['@type'] = { italic = true, bold = false },
        --   ['@function'] = { italic = true, bold = true },
        --   ['@field'] = { bold = true },
        --   ['@parameter'] = { italic = true },
        -- },
      }

      vim.cmd.colorscheme 'fluoromachine'
    end,
  },
  {
    'jaredgorski/spacecamp',
    enabled = false,
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme 'spacecamp'
    end,
  },
  {
    'diegoulloao/neofusion.nvim',
    enabled = false,
    lazy = false,
    priority = 1000,
    config = function()
      require('neofusion').setup {}

      vim.cmd.colorscheme 'neofusion'
    end,
    -- opts = { -- Default options:
    --   require('neofusion').setup {
    --     terminal_colors = true, -- add neovim terminal colors
    --     undercurl = true,
    --     underline = true,
    --     bold = true,
    --     italic = {
    --       strings = true,
    --       emphasis = true,
    --       comments = true,
    --       operators = false,
    --       folds = true,
    --     },
    --     strikethrough = true,
    --     invert_selection = false,
    --     invert_signs = false,
    --     invert_tabline = false,
    --     invert_intend_guides = false,
    --     inverse = true, -- invert background for search, diffs, statuslines and errors
    --     palette_overrides = {},
    --     overrides = {},
    --     dim_inactive = false,
    --     transparent_mode = false,
    --   },
  },
  --
  --
  -- NOTE: Plugins can also be added by using a table,
  -- with the first argument being the link and the following
  -- keys can be used to configure plugin behavior/loading/etc.
  --
  -- Use `opts = {}` to automatically pass options to a plugin's `setup()` function, forcing the plugin to be loaded.
  --
  -- modular approach: using `require 'path/name'` will
  -- include a plugin definition from file lua/path/name.lua
  --
  require 'kickstart/plugins/harpoon',

  require 'kickstart/plugins/render-markdown',

  require 'kickstart/plugins/gitsigns',

  require 'kickstart/plugins/which-key',

  require 'kickstart/plugins/telescope',

  require 'kickstart/plugins/lspconfig',

  require 'kickstart/plugins/conform',

  require 'kickstart/plugins/cmp',

  -- require 'kickstart/plugins/oxocarbon',

  require 'kickstart/plugins/todo-comments',

  require 'kickstart/plugins/mini',

  require 'kickstart/plugins/treesitter',

  -- The following comments only work if you have downloaded the kickstart repo, not just copy pasted the
  -- init.lua. If you want these files, they are in the repository, so you can just download them and
  -- place them in the correct locations.

  -- NOTE: Next step on your Neovim journey: Add/Configure additional plugins for Kickstart
  --
  --  Here are some example plugins that I've included in the Kickstart repository.
  --  Uncomment any of the lines below to enable them (you will need to restart nvim).
  --
  require 'kickstart.plugins.debug',
  require 'kickstart.plugins.indent_line',
  -- require 'kickstart.plugins.lint',
  require 'kickstart.plugins.autopairs',
  require 'kickstart.plugins.neo-tree',

  -- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
  --    This is the easiest way to modularize your config.
  --
  --  Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
  { import = 'custom.plugins' },
  --
  -- For additional information with loading, sourcing and examples see `:help lazy.nvim-🔌-plugin-spec`
  -- Or use telescope!
  -- In normal mode type `<space>sh` then write `lazy.nvim-plugin`
  -- you can continue same window with `<space>sr` which resumes last telescope search
}, {
  ui = {
    -- If you are using a Nerd Font: set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

require('lsp_lines').setup {}

vim.diagnostic.config {
  virtual_text = false,
}

-- dofile(vim.g.base46_cache .. 'defaults')
-- dofile(vim.g.base46_cache .. 'statusline')
--

-- Eviline config for lualine
-- Author: shadmansaleh
-- Credit: glepnir
local lualine = require 'lualine'

-- Color table for highlights
-- stylua: ignore
local colors = {
  bg       = '#202328',
  fg       = '#bbc2cf',
  yellow   = '#ECBE7B',
  cyan     = '#008080',
  darkblue = '#081633',
  green    = '#98be65',
  orange   = '#FF8800',
  violet   = '#a9a1e1',
  magenta  = '#c678dd',
  blue     = '#51afef',
  red      = '#ec5f67',
}

local conditions = {
  buffer_not_empty = function()
    return vim.fn.empty(vim.fn.expand '%:t') ~= 1
  end,
  hide_in_width = function()
    return vim.fn.winwidth(0) > 80
  end,
  check_git_workspace = function()
    local filepath = vim.fn.expand '%:p:h'
    local gitdir = vim.fn.finddir('.git', filepath .. ';')
    return gitdir and #gitdir > 0 and #gitdir < #filepath
  end,
}

-- Config
local config = {
  options = {
    -- Disable sections and component separators
    component_separators = '',
    section_separators = '',
    theme = {
      -- We are going to use lualine_c an lualine_x as left and
      -- right section. Both are highlighted by c theme .  So we
      -- are just setting default looks o statusline
      normal = { c = { fg = colors.fg, bg = colors.bg } },
      inactive = { c = { fg = colors.fg, bg = colors.bg } },
    },
  },
  sections = {
    -- these are to remove the default
    lualine_a = {},
    lualine_b = {},
    lualine_y = {},
    lualine_z = {},
    -- These will be filled later
    lualine_c = {},
    lualine_x = {},
  },
  inactive_sections = {
    -- these are to remove the defaults
    lualine_a = {},
    lualine_b = {},
    lualine_y = {},
    lualine_z = {},
    lualine_c = {},
    lualine_x = {},
  },
}

-- Inserts a component in lualine_c at left section
local function ins_left(component)
  table.insert(config.sections.lualine_c, component)
end

-- Inserts a component in lualine_x at right section
local function ins_right(component)
  table.insert(config.sections.lualine_x, component)
end
--
-- ins_left {
--   function()
--     return '▊'
--   end,
--   color = { fg = colors.blue }, -- Sets highlighting of component
--   padding = { left = 0, right = 1 }, -- We don't need space before this
-- }

ins_left {
  -- mode component
  function()
    return ''
  end,
  color = function()
    -- auto change color according to neovims mode
    local mode_color = {
      n = colors.red,
      i = colors.green,
      v = colors.blue,
      [''] = colors.blue,
      V = colors.blue,
      c = colors.magenta,
      no = colors.red,
      s = colors.orange,
      S = colors.orange,
      [''] = colors.orange,
      ic = colors.yellow,
      R = colors.violet,
      Rv = colors.violet,
      cv = colors.red,
      ce = colors.red,
      r = colors.cyan,
      rm = colors.cyan,
      ['r?'] = colors.cyan,
      ['!'] = colors.red,
      t = colors.red,
    }
    return { fg = mode_color[vim.fn.mode()] }
  end,
  padding = { left = 1, right = 1 },
}

-- ins_left {
--   'datetime',
--   style = '%H:%M:%S',
-- }

ins_left {
  'filename',
  cond = conditions.buffer_not_empty,
  color = { fg = colors.magenta, gui = 'bold' },
}

ins_left {
  -- filesize component
  'filesize',
  cond = conditions.buffer_not_empty,
}

ins_left { 'location' }

ins_left { 'progress', color = { fg = colors.fg, gui = 'bold' } }

ins_left { 'harpoon2', color_active = { fg = colors.darkblue } }

ins_left {
  'diagnostics',
  sources = { 'nvim_diagnostic' },
  symbols = { error = ' ', warn = ' ', info = ' ' },
  diagnostics_color = {
    error = { fg = colors.red },
    warn = { fg = colors.yellow },
    info = { fg = colors.cyan },
  },
}

-- Insert mid section. You can make any number of sections in neovim :)
-- for lualine it's any number greater then 2
ins_left {
  function()
    return '%='
  end,
}

ins_left {
  -- Lsp server name .
  function()
    local msg = 'No Active Lsp'
    local buf_ft = vim.api.nvim_get_option_value('filetype', { buf = 0 })
    local clients = vim.lsp.get_clients()
    if next(clients) == nil then
      return msg
    end
    for _, client in ipairs(clients) do
      local filetypes = client.config.filetypes
      if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
        return client.name
      end
    end
    return msg
  end,
  icon = ' :',
  color = { fg = '#ffffff', gui = 'bold' },
}

-- Add components to right sections
ins_right {
  'o:encoding', -- option component same as &encoding in viml
  fmt = string.upper, -- I'm not sure why it's upper case either ;)
  cond = conditions.hide_in_width,
  color = { fg = colors.green, gui = 'bold' },
}

ins_right {
  'fileformat',
  fmt = string.upper,
  icons_enabled = false, -- I think icons are cool but Eviline doesn't have them. sigh
  color = { fg = colors.green, gui = 'bold' },
}

ins_right {
  'branch',
  icon = '',
  color = { fg = colors.violet, gui = 'bold' },
}

ins_right {
  'diff',
  -- Is it me or the symbol for modified us really weird
  symbols = { added = ' ', modified = '󰝤 ', removed = ' ' },
  diff_color = {
    added = { fg = colors.green },
    modified = { fg = colors.orange },
    removed = { fg = colors.red },
  },
  cond = conditions.hide_in_width,
  padding = { right = 1 },
}

-- ins_right {
--   function()
--     return '▊'
--   end,
--   color = { fg = colors.fg },
--   padding = { left = 1 },
-- }

-- Now don't forget to initialize lualine
lualine.setup(config)

-- vim: ts=2 sts=2 sw=2 et
