return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = 'InsertEnter',
  -- below commented out, because above repo is supposed to be better
  -- 'github/copilot.vim',
  enabled = true,
  lazyload = false,
  config = function()
    require('copilot').setup {
      suggestion = { enabled = false },
      panel = { enabled = false },
    }

    -- Hotkey to toggle Copilot suggestions
    vim.api.nvim_set_keymap('n', '<leader>ap', ':Copilot toggle<CR>', { noremap = true, silent = true, desc = 'Toggle Co[p]ilot' })
  end,
}
