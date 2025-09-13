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
    vim.keymap.set('n', '<leader>Ns', '<cmd>Neogit kind=vsplit<CR>', { desc = 'Neogit Status' })
  end,
}
