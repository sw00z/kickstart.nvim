return {
  'p00f/clangd_extensions.nvim',
  ft = { 'c', 'cpp', 'objc', 'objcpp' },
  config = function()
    require('clangd_extensions').setup {}
  end,
  keys = {
    { '<leader>ch', '<cmd>ClangdSwitchSourceHeader<cr>', desc = '[C]langd Switch [H]eader/Source' },
    { '<leader>ct', '<cmd>ClangdTypeHierarchy<cr>', desc = '[C]langd [T]ype Hierarchy' },
    { '<leader>cc', '<cmd>ClangdCallHierarchy<cr>', desc = '[C]langd [C]all Hierarchy' },
  },
}
