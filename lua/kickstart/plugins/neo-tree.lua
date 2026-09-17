-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim
--
-- Opens as a LEFT-docked sidebar (not a float) so edgy.nvim can relocate the
-- filesystem/git/buffers source windows into its left column. Each source
-- window carries vim.b[buf].neo_tree_source, which edgy filters on to send the
-- three sources to three different slots.

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  cmd = 'Neotree',
  keys = {
    -- `\` reveals/toggles the file tree (close_window mapping below closes it
    -- from inside). edgy owns <leader>e for the full layout, so the tree has no
    -- <leader> binding of its own.
    { '\\', ':Neotree reveal position=left<CR>', desc = 'NeoTree reveal', silent = true },
  },
  opts = {
    close_if_last_window = true, -- don't keep nvim open on just the sidebar
    filesystem = {
      follow_current_file = { enabled = true }, -- track the active buffer in the tree
      window = {
        mappings = {
          ['\\'] = 'close_window',
        },
      },
    },
  },
}
