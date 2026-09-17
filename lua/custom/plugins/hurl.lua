-- hurl.nvim: run HTTP requests from .hurl files via the installed `hurl` binary
-- (~/.cargo/bin/hurl). Pure-Lua wrapper — no luarocks. Needs the `hurl`
-- treesitter parser (added in treesitter.lua). render-markdown.nvim is already
-- loaded as a kickstart plugin, so it is not re-declared here.
return {
  'jellydn/hurl.nvim',
  ft = 'hurl',
  dependencies = {
    'MunifTanjim/nui.nvim',
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  opts = {
    debug = false,
    show_notification = false,
    mode = 'split', -- response opens in a split rather than a popup
    -- Only jq is wired: prettier/tidy aren't installed, so html/xml responses
    -- render raw instead of failing on a missing formatter binary.
    formatters = {
      json = { 'jq' },
    },
    mappings = {
      close = 'q',
      next_panel = '<C-n>',
      prev_panel = '<C-p>',
    },
  },
  -- Everything under <leader>R (see the which-key group). The plugin's own
  -- defaults use <leader>a / <leader>t* / <leader>h, which collide with the
  -- AI / Tests / Harpoon groups.
  keys = {
    { '<leader>Rs', '<cmd>HurlRunnerAt<cr>', desc = '[R]est [s]end (cursor)' },
    { '<leader>Ra', '<cmd>HurlRunner<cr>', desc = '[R]est run [a]ll' },
    { '<leader>Re', '<cmd>HurlRunnerToEntry<cr>', desc = '[R]est run to [e]ntry' },
    { '<leader>Rl', '<cmd>HurlShowLastResponse<cr>', desc = '[R]est [l]ast response' },
    { '<leader>Rm', '<cmd>HurlToggleMode<cr>', desc = '[R]est toggle [m]ode' },
    { '<leader>Rv', '<cmd>HurlVerbose<cr>', desc = '[R]est [v]erbose' },
    -- Scope-aware replacement for :HurlManageVariable, which can only ever
    -- write the global variables.json. See lua/custom/hurl_vars.lua.
    {
      '<leader>Rg',
      function()
        require('custom.hurl_vars').manage()
      end,
      desc = '[R]est mana[g]e vars',
    },
    { '<leader>Rs', ':HurlRunner<cr>', desc = '[R]est [s]end (selection)', mode = 'v' },
  },
}
