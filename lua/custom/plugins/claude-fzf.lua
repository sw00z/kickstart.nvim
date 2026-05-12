return {
  'pittcat/claude-fzf.nvim',
  dependencies = {
    'ibhagwan/fzf-lua',
    'coder/claudecode.nvim',
  },
  cmd = {
    'ClaudeFzf',
    'ClaudeFzfFiles',
    'ClaudeFzfGrep',
    'ClaudeFzfBuffers',
    'ClaudeFzfGitFiles',
    'ClaudeFzfDirectory',
    'ClaudeFzfHealth',
  },
  keys = {
    -- Using <leader>cz prefix to avoid conflicts with your existing <leader>cf
    { '<leader>acsf', '<cmd>ClaudeFzfFiles<cr>', desc = 'Fzf files' },
    { '<leader>acsg', '<cmd>ClaudeFzfGrep<cr>', desc = 'Fzf grep' },
    { '<leader>acsb', '<cmd>ClaudeFzfBuffers<cr>', desc = 'Fzf buffers' },
    { '<leader>acsG', '<cmd>ClaudeFzfGitFiles<cr>', desc = 'Fzf git files' },
    { '<leader>acsd', '<cmd>ClaudeFzfDirectory<cr>', desc = 'Fzf directory' },
  },
  opts = {
    -- Batch processing
    batch_size = 10,
    show_progress = true,
    auto_open_terminal = true,
    auto_context = true, -- Tree-sitter based context extraction

    -- Notifications
    notifications = {
      enabled = true,
      show_progress = true,
      show_success = true,
      show_errors = true,
      use_snacks = true, -- Uses snacks.nvim if available
      timeout = 3000,
    },

    -- Disable default keymaps (we define our own above)
    keymaps = {
      files = '',
      grep = '',
      buffers = '',
      git_files = '',
      directory_files = '',
    },

    -- fzf-lua window options
    fzf_opts = {
      winopts = {
        height = 0.8,
        width = 0.8,
        backdrop = 60,
      },
    },

    -- Claude integration
    claude_opts = {
      auto_open_terminal = true,
      context_lines = 5,
      source_tag = 'claude-fzf',
    },

    -- Optional: Custom directories for ClaudeFzfDirectory
    directory_search = {
      directories = {
        -- Example: Add your common directories
        -- nvim_config = {
        --   path = vim.fn.expand("~/. config/nvim"),
        --   extensions = { "lua" },
        --   description = "Neovim Config"
        -- },
      },
    },
  },
}
