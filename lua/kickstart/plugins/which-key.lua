-- NOTE: Plugins can also be configured to run Lua code when they are loaded.
--
-- This is often very useful to both group configuration, as well as handle
-- lazy loading plugins that don't need to be loaded immediately at startup.
--
-- For example, in the following configuration, we use:
--  event = 'VimEnter'
--
-- which loads which-key before all the UI elements are loaded. Events can be
-- normal autocommands events (`:help autocmd-events`).
--
-- Then, because we use the `opts` key (recommended), the configuration runs
-- after the plugin has been loaded as `require(MODULE).setup(opts)`.

return {
  { -- Useful plugin to show you pending keybinds.
    'folke/which-key.nvim',
    event = 'VimEnter', -- Sets the loading event to 'VimEnter'
    opts = {
      -- delay between pressing a key and opening which-key (milliseconds)
      -- this setting is independent of vim.opt.timeoutlen
      delay = 0,
      icons = {
        -- set icon mappings to true if you have a Nerd Font
        mappings = vim.g.have_nerd_font,
        -- If you are using a Nerd Font: set icons.keys to an empty table which will use the
        -- default which-key.nvim defined Nerd Font icons, otherwise define a string table
        keys = vim.g.have_nerd_font and {} or {
          Up = '<Up> ',
          Down = '<Down> ',
          Left = '<Left> ',
          Right = '<Right> ',
          C = '<C-…> ',
          M = '<M-…> ',
          D = '<D-…> ',
          S = '<S-…> ',
          CR = '<CR> ',
          Esc = '<Esc> ',
          ScrollWheelDown = '<ScrollWheelDown> ',
          ScrollWheelUp = '<ScrollWheelUp> ',
          NL = '<NL> ',
          BS = '<BS> ',
          Space = '<Space> ',
          Tab = '<Tab> ',
          F1 = '<F1>',
          F2 = '<F2>',
          F3 = '<F3>',
          F4 = '<F4>',
          F5 = '<F5>',
          F6 = '<F6>',
          F7 = '<F7>',
          F8 = '<F8>',
          F9 = '<F9>',
          F10 = '<F10>',
          F11 = '<F11>',
          F12 = '<F12>',
        },
      },

      -- Document existing key chains
      spec = {
        { '<leader>a', group = '[A]I', mode = { 'n', 'v' } },
        { '<leader>ac', group = '[C]laude', mode = { 'n', 'v' } },
        { '<leader>acs', group = '[C]laude [S]earch' },
        { '<leader>ag', group = '[G]emini' },
        { '<leader>b', group = '[B]uffers' },
        { '<leader>c', group = '[C]ode/clangd' },
        { '<leader>d', group = '[D]ebug' },
        { '<leader>D', group = '[D]ockyard' },
        { '<leader>g', group = '[G]it' },
        { '<leader>h', group = '[H]arpoon', mode = { 'n', 'v' } },
        { '<leader>j', group = '[J]ob runner' },
        { '<leader>k', group = '[K]ernel/Cell' },
        { '<leader>L', group = '[L]SP', mode = { 'n', 'x' } },
        { '<leader>LW', group = '[L]SP [W]orkspace' },
        { '<leader>m', group = '[M]olten/Kernel' },
        { '<leader>M', group = '[M]arkdown', mode = { 'n', 'v' } }, -- mkdnflow table/list ops (markdown buffers only)
        { '<leader>n', group = '[N]otifications' },
        { '<leader>N', group = '[N]otes' },
        { '<leader>p', group = '[P]ackages (Pyworks)' },
        { '<leader>q', group = '[Q]uery (Database)' },
        { '<leader>r', group = '[R]un cells' },
        { '<leader>R', group = '[R]est (Hurl)' },
        { '<leader>s', group = '[S]earch' },
        { '<leader>t', group = '[T]ests' },
        { '<leader>u', group = '[U]I toggles' },
        { '<leader>v', group = '[V]iew (Aerial)' },
        { '<leader>x', group = 'Trouble/Diagnostics' },
        { '<leader>z', group = '[Z]oxide' },
        { ']', group = 'Next (treesitter/diagnostic)' },
        { '[', group = 'Prev (treesitter/diagnostic)' },
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
