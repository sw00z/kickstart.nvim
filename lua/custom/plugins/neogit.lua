return {
  'NeogitOrg/neogit',
  dependencies = {
    'nvim-lua/plenary.nvim', -- required
    'sindrets/diffview.nvim', -- optional - Diff integration

    -- Only one of these is needed.
    'nvim-telescope/telescope.nvim', -- optional
    -- "ibhagwan/fzf-lua",              -- optional
    -- "echasnovski/mini.pick",         -- optional
    -- "folke/snacks.nvim",             -- optional
  },
  opt = {
    integrations = {
      diffview = true, -- enable diffview integration
      telescope = true, -- enable telescope integration
      -- fzf_lua = true,  -- enable fzf_lua integration
      -- mini_pick = true,-- enable mini_pick integration
      -- snacks = true,   -- enable snacks.nvim integration
    },
  },
  config = function(_, opts)
    local neogit = require 'neogit'
    local is_neogit_open = false

    vim.keymap.set('n', '<leader>gn', function()
      if is_neogit_open then
        neogit.close()
        is_neogit_open = false
      else
        neogit.open { kind = 'floating' }
        is_neogit_open = true
      end
    end, { desc = 'Toggle Neogit' })
  end,
}
