return {
  'coder/claudecode.nvim',
  dependencies = { 'folke/snacks.nvim' },
  opts = {
    -- Auto-start WebSocket server
    auto_start = true,
    log_level = 'info',

    -- Selection tracking (Claude sees what you select)
    track_selection = true,

    -- Terminal configuration
    terminal = {
      split_side = 'right',
      split_width_percentage = 0.45,
      provider = 'snacks', -- or "native"
    },

    -- Diff behavior
    diff_opts = {
      auto_close_on_accept = true,
      vertical_split = true,
    },
  },
  keys = {
    { '<leader>act', '<cmd>ClaudeCode<cr>', desc = 'Toggle Claude' },
    { '<leader>acF', '<cmd>ClaudeCodeFocus<cr>', desc = 'Focus Claude' },
    { '<leader>acr', '<cmd>ClaudeCode --resume<cr>', desc = 'Resume conversation' },
    { '<leader>acC', '<cmd>ClaudeCode --continue<cr>', desc = 'Continue last' },
    { '<leader>acb', '<cmd>ClaudeCodeAdd %<cr>', desc = 'Add current buffer' },
    { '<leader>acs', '<cmd>ClaudeCodeSend<cr>', mode = 'v', desc = 'Send selection' },
    { '<leader>aca', '<cmd>ClaudeCodeDiffAccept<cr>', desc = 'Accept diff' },
    { '<leader>acd', '<cmd>ClaudeCodeDiffDeny<cr>', desc = 'Deny diff' },
    -- File tree integration
    {
      '<leader>acf',
      '<cmd>ClaudeCodeTreeAdd<cr>',
      desc = 'Add file to Claude',
      ft = { 'NvimTree', 'neo-tree', 'oil', 'minifiles' },
    },
  },
  config = function(_, opts)
    require('claudecode').setup(opts)

    -- ============================================
    -- TERMINAL MODE NAVIGATION (THE FIX)
    -- ============================================
    -- These keymaps work INSIDE the terminal buffer

    local term_opts = { noremap = true, silent = true }

    -- Escape terminal mode to normal mode
    vim.keymap.set('t', '<C-\\><C-n>', '<C-\\><C-n>', term_opts)
    vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', term_opts)

    -- Window navigation FROM terminal mode (matches tmux/nvim ctrl+hjkl)
    vim.keymap.set('t', '<C-h>', '<C-\\><C-n><C-w>h', term_opts)
    vim.keymap.set('t', '<C-j>', '<C-\\><C-n><C-w>j', term_opts)
    vim.keymap.set('t', '<C-k>', '<C-\\><C-n><C-w>k', term_opts)
    vim.keymap.set('t', '<C-l>', '<C-\\><C-n><C-w>l', term_opts)

    -- Toggle Claude from terminal mode (so you can hide it)
    vim.keymap.set('t', '<C-\\>c', '<cmd>ClaudeCode<cr>', term_opts)
  end,
}
