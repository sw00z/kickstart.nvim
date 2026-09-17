-- Seamless Ctrl-h/j/k/l movement and Alt-h/j/k/l resize between Neovim splits
-- and herdr panes. Counterpart to christoomey/vim-tmux-navigator: that plugin
-- still handles tmux/bare sessions, this one loads only inside herdr (both bind
-- the same keys, gated by HERDR_ENV to stay mutually exclusive). At a split edge,
-- herdr-splits calls `herdr pane focus/resize --direction` to cross into the
-- neighbouring herdr pane. The herdr side is the `herdr-splits` plugin + the
-- ctrl/alt+hjkl bindings in ~/.config/herdr/config.toml.
return {
  'lmilojevicc/herdr-splits.nvim',
  cond = vim.env.HERDR_ENV == '1',
  event = 'VeryLazy',
  build = 'lua require("herdr-splits").sync_herdr()',
  config = function()
    require('herdr-splits').setup {
      default_amount = 0.03,
      neovim_amount = 3,
      at_edge = 'wrap',
      ignored_buftypes = { 'nofile', 'quickfix', 'prompt', 'help', 'terminal' },
      ignored_filetypes = {
        'NvimTree',
        'neo-tree',
        'snacks_dashboard',
        'snacks_explorer',
        'snacks_picker',
        'dadbod-ui',
        'dbout',
        'aerial',
        'Outline',
        'Trouble',
        'quickfix',
      },
      auto_sync_herdr = true,
    }
  end,
  keys = {
    {
      '<C-h>',
      function()
        require('herdr-splits').move_cursor_left()
      end,
      desc = 'Navigate left',
    },
    {
      '<C-j>',
      function()
        require('herdr-splits').move_cursor_down()
      end,
      desc = 'Navigate down',
    },
    {
      '<C-k>',
      function()
        require('herdr-splits').move_cursor_up()
      end,
      desc = 'Navigate up',
    },
    {
      '<C-l>',
      function()
        require('herdr-splits').move_cursor_right()
      end,
      desc = 'Navigate right',
    },
    {
      '<M-h>',
      function()
        require('herdr-splits').resize_left()
      end,
      desc = 'Resize left',
    },
    {
      '<M-j>',
      function()
        require('herdr-splits').resize_down()
      end,
      desc = 'Resize down',
    },
    {
      '<M-k>',
      function()
        require('herdr-splits').resize_up()
      end,
      desc = 'Resize up',
    },
    {
      '<M-l>',
      function()
        require('herdr-splits').resize_right()
      end,
      desc = 'Resize right',
    },
  },
}
