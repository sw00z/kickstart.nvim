-- Colorscheme collection
-- Active scheme loads eagerly; the rest load on VeryLazy (after the UI is drawn)
-- so they sit on the runtimepath and the Telescope picker (<leader>sc) can list
-- them — `lazy = true` keeps a plugin off rtp, so getcompletion never sees it.
-- The picker only applies for the session, so the choice is persisted to a state
-- file and re-applied on the next start (autocmd + loader).

-- ~/.local/state/nvim/colorscheme.txt
local state_file = vim.fs.normalize(vim.fn.stdpath 'state' .. '/colorscheme.txt')

-- Write synchronously (not deferred) so a scheme picked right before :q flushes.
local function save_colorscheme(name)
  if not name or name == '' then
    return
  end
  local fd = io.open(state_file, 'w')
  if fd then
    fd:write(name)
    fd:close()
  end
end

-- Read the last-active colorscheme name, or nil when nothing is stored yet.
local function read_colorscheme()
  local fd = io.open(state_file, 'r')
  if not fd then
    return nil
  end
  local name = fd:read '*l'
  fd:close()
  return (name and name ~= '') and name or nil
end

return {
  -- ACTIVE COLORSCHEME — owns startup scheme selection + cross-session persistence.
  {
    'wtfox/jellybeans.nvim',
    lazy = false,
    priority = 1000,
    opts = {},
    config = function()
      -- Persist every colorscheme change (ev.match = new scheme). A cancelled
      -- picker reverts and re-fires ColorScheme, so the original is kept.
      -- styler.nvim switches the global colorscheme to apply a prose theme
      -- per-window, but sets eventignore = 'all' first, so those switches never
      -- reach this callback today. The guard stays so a future styler that drops
      -- eventignore can't persist a prose theme over the code one — styler.lua
      -- publishes the name, so there is nothing to keep in sync by hand.
      vim.api.nvim_create_autocmd('ColorScheme', {
        callback = function(ev)
          if ev.match ~= vim.g.styler_prose then
            save_colorscheme(ev.match)
          end
        end,
      })

      -- One italic policy across the themes that opt in, plus :ItalicPolicy and
      -- <leader>ui to toggle it against each theme's own defaults. 'zen*' is
      -- needed alongside '*bones*' — zenwritten and zenburned have no "bones".
      require('custom.theme_italics').attach {
        'candyland',
        'vimdark',
        'vimlight',
        'vimdark-pastel',
        'noirbuddy*',
        'vague',
        'modus*',
        'mellifluous*',
        '*bones*',
        'zen*',
      }

      -- One readability floor over every theme, not just the opt-in list: the
      -- surfaces `K` renders documentation on. Attached before the scheme is
      -- applied below so the restored theme is covered on the first paint.
      require('custom.theme_readability').attach()

      -- Re-apply the saved scheme; pcall falls back to jellybeans if its plugin
      -- was removed, then self-heals by rewriting the file.
      local saved = read_colorscheme()
      if not (saved and pcall(vim.cmd.colorscheme, saved)) then
        vim.cmd.colorscheme 'jellybeans'
      end
    end,
  },

  -- VeryLazy-LOADED COLORSCHEMES (on rtp after startup so <leader>sc lists them)
  {
    'rose-pine/neovim',
    name = 'rose-pine',
    event = 'VeryLazy',
  },
  {
    'ramojus/mellifluous.nvim',
    event = 'VeryLazy',
    -- 4 more colorsets are pickable through colors/mellifluous-*.lua; their
    -- per-colorset overrides live in custom/theme_variants.lua. `styles` is left
    -- alone — its defaults already match the italic policy.
    opts = {
      -- edgy docks many small windows, where per-window gutter bands read as noise.
      flat_background = {
        line_numbers = true,
        floating_windows = true,
        cursor_line_number = true,
      },
      dim_inactive = false, -- vimade already dims inactive windows
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
    event = 'VeryLazy',
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
    event = 'VeryLazy',
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
    event = 'VeryLazy',
    config = function()
      local alduin = require 'alduin'
      alduin.palette.bg = '#1a1410'
    end,
  },
  {
    'embark-theme/vim',
    event = 'VeryLazy',
  },
  {
    'lunacookies/vim-colors-xcode',
    event = 'VeryLazy',
    config = function()
      -- VimScript theme with per-variant g: vars (no Lua setup). Apply the same
      -- prefs to every xcode variant so any one picked honors them.
      for _, v in ipairs { 'xcode', 'xcodedark', 'xcodedarkhc', 'xcodehc', 'xcodelight', 'xcodelighthc', 'xcodewwdc' } do
        vim.g[v .. '_green_comments'] = 1
        vim.g[v .. '_emph_funcs'] = 1
      end
    end,
  },
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    event = 'VeryLazy',
    opts = {
      flavour = 'macchiato',
    },
  },
  {
    'Iron-E/nvim-highlite',
    event = 'VeryLazy',
    config = function()
      require('highlite').setup { generator = { plugins = { vim = false }, syntax = false } }
    end,
  },
  {
    'mellow-theme/mellow.nvim',
    event = 'VeryLazy',
    config = function()
      vim.g.mellow_transparent = true
      vim.g.mellow_italic_functions = true
      vim.g.mellow_bold_variables = true
    end,
  },
  {
    'AlexvZyl/nordic.nvim',
    event = 'VeryLazy',
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
    event = 'VeryLazy',
    tag = 'v2.0.1',
    opts = {
      theme = {
        contrast = 'high',
        -- Boolean, not the string 'true': flow reads this key both ways —
        -- colors.lua:85 compares `== true` and colors.lua:181 tests truthiness —
        -- so a string produced a half-transparent theme. Its float bg is
        -- transparent either way (colors.lua:93 is unconditional), which is what
        -- LspFloatNormal covers.
        transparent = true,
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
    event = 'VeryLazy',
  },
  {
    'zootedb0t/citruszest.nvim',
    event = 'VeryLazy',
    config = function()
      require('citruszest').setup {
        option = {
          transparent = false,
          bold = true,
          italic = true,
        },
        -- No `style` override: the previous Constant fg was #232323, the
        -- palette's own `black`, which measures 1.19:1 against citruszest's
        -- #121212 background. Constant is what @constant, @attribute,
        -- @type.qualifier and @lsp.type.enumMember link to, so const qualifiers
        -- and enum members were invisible in a signature hover. The theme's own
        -- orange is 6.95:1.
      }
    end,
  },
  {
    'maxmx03/fluoromachine.nvim',
    event = 'VeryLazy',
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
    event = 'VeryLazy',
  },
  {
    'diegoulloao/neofusion.nvim',
    event = 'VeryLazy',
    config = function()
      require('neofusion').setup {}
    end,
  },
  {
    'EdenEast/nightfox.nvim',
    event = 'VeryLazy',
  },
  {
    'nyoom-engineering/oxocarbon.nvim',
    event = 'VeryLazy',
    config = function()
      -- Apply transparent-bg overrides only when oxocarbon is selected
      vim.api.nvim_create_autocmd('ColorScheme', {
        pattern = 'oxocarbon',
        callback = function()
          vim.opt.background = 'dark'
          vim.api.nvim_set_hl(0, 'Normal', { bg = 'none' })
          vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'none' })
          vim.api.nvim_set_hl(0, 'NormalNC', { bg = 'none' })
        end,
      })
    end,
  },
  {
    'AmberLehmann/candyland.nvim',
    -- VeryLazy (not lazy = true) so the plugin actually loads after startup;
    -- without this its name is invisible to vim.fn.getcompletion("", "color")
    -- and Telescope's <leader>sc picker can't list it.
    -- Candyland leaves most groups upright; the shared italic policy in
    -- custom/theme_italics.lua re-applies them (this name is in its attach list).
    event = 'VeryLazy',
    priority = 1000,
  },

  -- ADDED THEMES (VeryLazy so they appear in the picker)
  {
    'rebelot/kanagawa.nvim',
    event = 'VeryLazy',
    opts = {
      compile = false,
      dimInactive = true,
      theme = 'wave', -- also pickable: kanagawa-dragon, kanagawa-lotus
    },
  },
  {
    'scottmckendry/cyberdream.nvim',
    event = 'VeryLazy',
    opts = {
      transparent = false,
      italic_comments = true,
      terminal_colors = true,
    },
  },
  {
    'sainnhe/gruvbox-material',
    event = 'VeryLazy',
    config = function()
      -- VimScript theme: reads these g: vars when :colorscheme runs, so set
      -- them at load, before the picker applies it.
      vim.g.gruvbox_material_background = 'medium' -- soft | medium | hard
      vim.g.gruvbox_material_foreground = 'material' -- material | mix | original
      vim.g.gruvbox_material_better_performance = 1
      vim.g.gruvbox_material_enable_italic = 1
    end,
  },

  -- MONOCHROME / PASTEL THEMES
  -- Each theme's own italic switches are left at their authored defaults so
  -- `:ItalicPolicy off` shows it as written; the policy strips the dense groups
  -- and adds its own when on. Variants these plugins expose only through a
  -- setup() argument are reached through colors/*.lua — see custom/theme_variants.lua.
  {
    'ldelossa/vimdark',
    -- Pure VimScript: no setup(), no g: options. `vimdark` and `vimlight` load
    -- as-is; the pastel accent overlay is a separate pickable name
    -- (colors/vimdark-pastel.lua) so the original stays authentic.
    event = 'VeryLazy',
  },
  {
    'jesseleite/noirbuddy.nvim',
    dependencies = { 'tjdevries/colorbuddy.nvim' },
    event = 'VeryLazy',
    -- Deliberately no `opts` and no `config`: noirbuddy.setup() applies the
    -- colorscheme inline (termguicolors, background, every highlight,
    -- g:colors_name), and lazy calls setup only when a spec carries one of those
    -- keys — so an opts table here would repaint over whatever scheme startup just
    -- restored. The presets and the custom palettes go through colors/noirbuddy*.lua
    -- instead — including the bare `noirbuddy` name, whose local stub shadows this
    -- plugin's colors file to apply the retuned palette. colorbuddy adds its own
    -- `colorbuddy` and `gruvbuddy` names to the picker; unavoidable once it is on
    -- the runtimepath.
  },
  {
    'zenbones-theme/zenbones.nvim',
    dependencies = { 'rktjmp/lush.nvim' },
    event = 'VeryLazy',
    config = function()
      -- No setup(): each variant reads vim.g.<name>_<option> when :colorscheme
      -- runs, so every option has to be set once per name (same shape as the
      -- vim-colors-xcode loop above). Both lighten_* and darken_* are set — only
      -- the pair matching the current 'background' is read, so the other half is
      -- inert and a background flip stays covered.
      local variants = {
        'zenbones',
        'zenwritten',
        'neobones',
        'vimbones',
        'rosebones',
        'forestbones',
        'nordbones',
        'tokyobones',
        'seoulbones',
        'duckbones',
        'zenburned',
        'kanagawabones',
        'randombones',
        'randombones_dark',
        'randombones_light',
      }
      for _, v in ipairs(variants) do
        vim.g[v .. '_solid_line_nr'] = true
        vim.g[v .. '_solid_float_border'] = true -- edgy/telescope/lsp_lines floats need an edge
        vim.g[v .. '_colorize_diagnostic_underline_text'] = false -- lsp_lines already prints the text
        vim.g[v .. '_lighten_comments'] = 46 -- default 38
        vim.g[v .. '_darken_comments'] = 46
        vim.g[v .. '_lighten_cursor_line'] = 6 -- default 4
        vim.g[v .. '_darken_cursor_line'] = 6
        -- Not set: lighten/darken_noncurrent_window — vimade owns inactive dimming.
      end
      -- Per-variant character. zenwritten is zenbones with zero chroma, the
      -- truest monochrome here, so push it to near-black.
      vim.g.zenwritten_darkness = 'stark'
      vim.g.zenbones_darkness = 'warm'
      vim.g.zenburned_darkness = 'warm'
      vim.g.vimbones_lightness = 'dim'
    end,
  },
  {
    'miikanissi/modus-themes.nvim',
    event = 'VeryLazy',
    -- All 9 style/variant combinations are pickable through colors/modus*.lua,
    -- including the three names modus ships itself — config.extend mutates stored
    -- options permanently, so an unpinned name would inherit whichever variant was
    -- selected last.
    opts = {
      variants = { modus_operandi = 'default', modus_vivendi = 'default' },
      -- edgy docks many small windows, where gutter bands read as noise.
      line_nr_column_background = false,
      sign_column_background = false,
      dim_inactive = false, -- vimade already dims inactive windows
    },
  },
  {
    'vague-theme/vague.nvim',
    event = 'VeryLazy',
    opts = {
      colors = {
        bg = '#101015', -- one step under the stock #141415, matching the collection
        inactiveBg = '#101015', -- vimade dims; a second inactive bg double-dims
        comment = '#6E6E88', -- lifted from #606079 for readability
      },
    },
  },
}
