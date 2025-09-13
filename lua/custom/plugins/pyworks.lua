return {
  'jeryldev/pyworks.nvim',
  dependencies = {
    -- Required for notebook support
    {
      'benlubas/molten-nvim',
      version = '^1.0.0',
      build = ':UpdateRemotePlugins',
    },
    '3rd/image.nvim', -- For inline plots/images
    'GCBallesteros/jupytext.nvim', -- For .ipynb file support
  },
  lazy = false, -- Load immediately for autocmds
  config = function()
    require('pyworks').setup {
      -- Configuration options (optional)
      python = {
        preferred_venv_name = '.venv',
        use_uv = true, -- Use uv when available
      },
      auto_activate_venv = true,
    }
  end,
}
