return {
  'christoomey/vim-tmux-navigator',
  -- Load only outside a herdr session (tmux or bare nvim). Inside herdr,
  -- herdr-splits.nvim owns <C-h/j/k/l> instead (see herdr-splits.lua). Both bind
  -- the same keys, so HERDR_ENV keeps them mutually exclusive per session.
  cond = vim.env.HERDR_ENV ~= '1',
  cmd = {
    'TmuxNavigateLeft',
    'TmuxNavigateDown',
    'TmuxNavigateUp',
    'TmuxNavigateRight',
    'TmuxNavigatePrevious',
    'TmuxNavigatorProcessList',
  },
  keys = {
    { '<c-h>', '<cmd><C-U>TmuxNavigateLeft<cr>' },
    { '<c-j>', '<cmd><C-U>TmuxNavigateDown<cr>' },
    { '<c-k>', '<cmd><C-U>TmuxNavigateUp<cr>' },
    { '<c-l>', '<cmd><C-U>TmuxNavigateRight<cr>' },
    { '<c-\\>', '<cmd><C-U>TmuxNavigatePrevious<cr>' },
  },
}
