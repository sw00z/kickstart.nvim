-- Colorscheme variants their plugins do not ship as loadable names. mellifluous
-- exposes colorsets through :Mellifluous, noirbuddy through a setup() argument,
-- modus through a config table — none of which the Telescope picker (<leader>sc)
-- or the startup loader in custom/plugins/colorschemes.lua can reach, since both
-- only speak `:colorscheme <name>`.
--
-- Each variant therefore gets a one-line colors/<name>.lua stub calling in here.
-- ~/.config/nvim is always runtimepath entry #1, so the stubs are visible to
-- vim.fn.getcompletion('', 'color') with no plugin loaded.
--
-- Why none of these run `:colorscheme <base>`: :h :colorscheme — "Doesn't work
-- recursively". load_colors() holds a guard across the whole load, so a nested
-- :colorscheme from a colors/ file sources nothing and fires no event. Each
-- function drives the theme's own apply path instead.
--
-- Why each function must load its own plugin: lazy's ColorSchemePre hook
-- (lazy/core/loader.lua:515) returns early when the name already resolves, which
-- a stub always does. `require` covers the Lua themes through lazy's module
-- loader; vimdark is VimScript with no module, so it needs an explicit load.
--
-- Why g:colors_name is claimed last: noirbuddy and modus hardcode it to their own
-- base name, and three consumers read it to decide what to reload — Telescope's
-- cancel-restore, styler.nvim's per-window themes, and Neovim's re-source of
-- colors/<colors_name>.* on a 'background' change.
local pastel = require 'custom.theme_pastel'

local M = {}

-- `noirbuddy` is deliberately absent: colors/noirbuddy.lua shadows the plugin's own
-- file and falls through to the retuned palette in theme_pastel. `noirbuddy-minimal`
-- is what keeps the plugin's authentic preset reachable under a name of its own.
local NOIRBUDDY = {
  ['noirbuddy-minimal'] = { preset = 'minimal' },
  ['noirbuddy-oxide'] = { preset = 'oxide' },
  ['noirbuddy-slate'] = { preset = 'slate' },
  ['noirbuddy-kiwi'] = { preset = 'kiwi' },
  ['noirbuddy-miami-nights'] = { preset = 'miami-nights' },
  ['noirbuddy-northern-lights'] = { preset = 'northern-lights' },
  ['noirbuddy-crt-amber'] = { preset = 'crt-amber' },
  ['noirbuddy-crt-green'] = { preset = 'crt-green' },
  ['noirbuddy-christmas'] = { preset = 'christmas' },
}

-- Prefixed because bare `alduin` and `kanagawa-dragon` are taken by alduin.nvim
-- and kanagawa.nvim. Overrides are keyed by colorset name, which wins over the
-- global block, so the base `mellifluous` colorset in colorschemes.lua is
-- untouched and a stale entry from a previous selection stays inert.
local MELLIFLUOUS = {
  ['mellifluous-mountain'] = {
    colorset = 'mountain',
    mountain = {
      color_overrides = {
        dark = {
          colors = function(colors)
            -- Stock operators is dark_red, the same hex as `red`, so operators
            -- currently compete with error diagnostics.
            return { operators = colors.comments:lightened(20) }
          end,
        },
      },
    },
  },
  ['mellifluous-tender'] = {
    colorset = 'tender',
    tender = {
      color_overrides = {
        dark = {
          -- #282828 is the lightest bg in the set; join the darker register.
          bg = function(bg)
            return bg:darkened(10)
          end,
          colors = function(colors)
            -- #d3b987 is the loudest token on screen.
            return { strings = colors.strings:desaturated(15) }
          end,
        },
      },
    },
  },
  ['mellifluous-alduin'] = {
    colorset = 'alduin',
    alduin = {
      color_overrides = {
        dark = {
          -- Match the standalone alduin.nvim spec's #1a1410.
          bg = function(bg)
            return bg:darkened(6)
          end,
          colors = function(colors)
            -- Stock comments is a very dim olive (#87875f).
            return { comments = colors.comments:lightened(12) }
          end,
        },
      },
    },
  },
  ['mellifluous-kanagawa-dragon'] = {
    colorset = 'kanagawa_dragon',
    kanagawa_dragon = {
      -- Palette is canonical; only the background joins the darker register.
      color_overrides = {
        dark = {
          bg = function(bg)
            return bg:darkened(4)
          end,
        },
      },
    },
  },
}

-- Every modus entry pins its full style/variant pair, including the three names
-- modus ships itself — config.extend mutates stored options permanently, so an
-- unpinned name would inherit whichever variant was selected last.
local MODUS = {
  modus = { 'auto', 'default' },
  modus_operandi = { 'modus_operandi', 'default' },
  modus_operandi_tinted = { 'modus_operandi', 'tinted' },
  modus_operandi_deuteranopia = { 'modus_operandi', 'deuteranopia' },
  modus_operandi_tritanopia = { 'modus_operandi', 'tritanopia' },
  modus_vivendi = { 'modus_vivendi', 'default' },
  modus_vivendi_tinted = { 'modus_vivendi', 'tinted' },
  modus_vivendi_deuteranopia = { 'modus_vivendi', 'deuteranopia' },
  modus_vivendi_tritanopia = { 'modus_vivendi', 'tritanopia' },
}

-- The preamble every colors/ file runs before repainting.
local function clear()
  if vim.g.colors_name then
    vim.cmd 'hi clear'
  end
  if vim.fn.exists 'syntax_on' == 1 then
    vim.cmd 'syntax reset'
  end
end

---@param name string the colors/<name>.lua this was called from
function M.noirbuddy(name)
  -- noirbuddy.plugins and .languages build their Groups at require time and are
  -- then package.loaded-cached, and colorbuddy Colors cascade to dependent Colors
  -- but not to Groups. Without dropping these, a second setup() repaints the core
  -- and treesitter groups and leaves every plugin highlight on the last preset.
  for module in pairs(package.loaded) do
    if module:find '^noirbuddy%.plugins' or module:find '^noirbuddy%.languages' then
      package.loaded[module] = nil
    end
  end

  clear()
  -- setup() applies inline: termguicolors, background, every highlight, and
  -- g:colors_name = 'noirbuddy'.
  require('noirbuddy').setup(NOIRBUDDY[name] or pastel.noirbuddy_opts(name))

  if not NOIRBUDDY[name] then
    pastel.refine(name)
  end
  vim.g.colors_name = name
end

---@param name string
function M.mellifluous(name)
  -- setup() only records config; apply() reads it. clear_highlights drops the
  -- table the previous colorset filled, or its groups leak into this one — the
  -- same two steps mellifluous's own :Mellifluous command takes.
  require('mellifluous').setup(MELLIFLUOUS[name])
  require('mellifluous.utils.highlighter').clear_highlights()
  clear()
  require('mellifluous').apply()
  vim.g.colors_name = name
end

---@param name string
function M.modus(name)
  local style, variant = MODUS[name][1], MODUS[name][2]
  -- 'auto' resolves against 'background', so pin both styles for it.
  local variants = style == 'auto' and { modus_operandi = variant, modus_vivendi = variant } or { [style] = variant }
  -- load() runs `hi clear` itself and hardcodes g:colors_name = 'modus'.
  require('modus-themes').load { style = style, variants = variants }
  vim.g.colors_name = name
end

---@param name string
function M.vimdark(name)
  -- vimdark is pure VimScript, so nothing pulls it onto the runtimepath the way
  -- `require` does for the others — :runtime would find nothing.
  require('lazy').load { plugins = { 'vimdark' } }
  clear()
  -- :runtime is the escape hatch :h :colorscheme recommends for reusing a scheme
  -- under another name; it is not :colorscheme, so the recursion guard is not hit.
  vim.cmd 'runtime colors/vimdark.vim'
  pastel.vimdark()
  vim.g.colors_name = name
end

return M
