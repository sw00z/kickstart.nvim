return {
  'luckasRanarison/nvim-devdocs',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  config = function()
    require('nvim-devdocs').setup {
      wrap = true,
      previewer_cmd = 'glow',
      cmd_args = { '-s', 'dark', '-w', '80' },
      picker_cmd = true,
      picker_cmd_args = { '-s', 'dark' },
      ensure_installed = { 'rust', 'go', 'javascript', 'python', 'html' },
    }

    vim.keymap.set('n', '<leader>o', ':DevdocsOpenCurrentFloat<CR>', { desc = 'Open DevDocs floating window' })
  end,
}
