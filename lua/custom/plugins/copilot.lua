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
  end,
}
