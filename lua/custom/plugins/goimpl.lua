-- Interface-stub generator for Go. Cursor on a struct's type name, fire the
-- picker, choose an interface (e.g. io.ReadWriteCloser) -> inserts method stubs
-- with correct signatures and receiver (pointer/value inferred from the type).
-- Treesitter locates the type under cursor; the josharian/impl binary does the
-- codegen (go install github.com/josharian/impl@latest); telescope is the picker.
return {
  'edolphin-ydf/goimpl.nvim',
  ft = 'go',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
    'nvim-telescope/telescope.nvim',
  },
  config = function()
    require('telescope').load_extension 'goimpl'
  end,
  keys = {
    {
      '<leader>ci',
      function()
        require('telescope').extensions.goimpl.goimpl {}
      end,
      ft = 'go',
      desc = 'Golang [I]mplement [I]nterface',
    },
  },
}
