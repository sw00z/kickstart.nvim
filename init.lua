--[[
swooz nvim config — kickstart-modular fork (sw00z/kickstart.nvim).

Layout:
  init.lua                     ← entry point (this file). Sets leader, then loads:
  lua/options.lua              ← :h vim.opt settings (numbers, indent, clipboard, …)
  lua/lazy-bootstrap.lua       ← installs lazy.nvim if missing
  lua/lazy-plugins.lua         ← lazy.setup(): the plugin manifest
  lua/keymaps.lua              ← global non-plugin keymaps (Quarto runner, Molten init, …)
  lua/kickstart/plugins/*.lua  ← kickstart-derived specs (lspconfig, conform, lint, debug,
                                 treesitter, telescope, which-key, mini, harpoon, …)
  lua/custom/plugins/*.lua     ← personal additions; auto-imported by lazy.nvim
                                 (snacks, ui.nvim, claudecode, gemini, neogit, projector,
                                  pyworks/molten, neotest, dadbod-grip + dbee, etc.)

Daily diagnostics:
  :Lazy        — plugin status
  :Mason       — LSP / tool installer
  :checkhealth — full system diagnosis (run after big changes)
  :WhichKey <leader> — live keymap surface

Where to add things:
  new language LSP/format/lint  → kickstart/plugins/{lspconfig,conform,lint}.lua
  new treesitter parser         → kickstart/plugins/treesitter.lua
  new plugin                    → drop a file in lua/custom/plugins/

  Lua-newcomer reference: https://learnxinyminutes.com/docs/lua/  +  :help lua-guide
--]]

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true
vim.g.wrap_lines = true

-- NvChad UI settings
-- require 'chadrc'

-- [[ Setting options ]]
require 'options'

-- [[ Install `lazy.nvim` plugin manager ]]
require 'lazy-bootstrap'

-- [[ Configure and install plugins ]]
require 'lazy-plugins'

-- [[ Basic Keymaps ]]
require 'keymaps'

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
