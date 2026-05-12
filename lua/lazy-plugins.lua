-- [[ Configure and install plugins ]]
--
--  To check the current status of your plugins, run
--    :Lazy
--
--  You can press `?` in this menu for help. Use `:q` to close the window
--
--  To update plugins you can run
--    :Lazy update

require('lazy').setup({
  -- Plain string specs (no extra config)
  'tpope/vim-dadbod', -- Database interaction
  'kristijanhusak/vim-dadbod-ui', -- UI for executing cmds & viewing tables
  'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically
  'nanotee/zoxide.vim', -- Easily cd into directories through rankings of usage
  { 'junegunn/fzf' }, -- fzf for usage within vim

  {
    'https://git.sr.ht/~whynothugo/lsp_lines.nvim',
    config = function()
      require('lsp_lines').setup()
      vim.diagnostic.config { virtual_text = false }
      vim.keymap.set('n', '<leader>l', require('lsp_lines').toggle, { desc = 'Toggle LSP lines' })
    end,
  },

  -- Modular kickstart plugins (lua/kickstart/plugins/*.lua)
  require 'kickstart/plugins/harpoon',
  require 'kickstart/plugins/render-markdown',
  require 'kickstart/plugins/gitsigns',
  require 'kickstart/plugins/which-key',
  require 'kickstart/plugins/telescope',
  require 'kickstart/plugins/lspconfig',
  require 'kickstart/plugins/conform',
  require 'kickstart/plugins/cmp',
  require 'kickstart/plugins/todo-comments',
  require 'kickstart/plugins/mini',
  require 'kickstart/plugins/treesitter',
  require 'kickstart.plugins.debug',
  require 'kickstart.plugins.lint',
  require 'kickstart.plugins.autopairs',
  require 'kickstart.plugins.neo-tree',

  -- Auto-import everything in lua/custom/plugins/*.lua
  -- Add new plugins by dropping a file in that directory.
  { import = 'custom.plugins' },
}, {
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

-- vim: ts=2 sts=2 sw=2 et
