return {
  'p00f/clangd_extensions.nvim',
  cmd = { 'Skel', 'CppConstructor', 'CppExtract', 'CppInline', 'CppIncludes' },
  ft = { 'c', 'cpp', 'objc', 'objcpp' },
  config = function()
    require('clangd_extensions').setup {}
    require('custom.cpp_actions').setup()
  end,
  keys = {
    { '<leader>cS', '<cmd>Skel<cr>', desc = '[C]++ file [S]keleton' },
    { '<leader>cC', '<cmd>CppConstructor<cr>', desc = '[C]++ memberwise [C]onstructor' },
    { '<leader>cE', '<cmd>CppExtract<cr>', desc = '[C]++ [E]xtract definition to source' },
    { '<leader>cI', '<cmd>CppIncludes<cr>', desc = '[C]++ [I]nclude actions' },
    { '<leader>ch', '<cmd>ClangdSwitchSourceHeader<cr>', desc = '[C]langd Switch [H]eader/Source' },
    { '<leader>ct', '<cmd>ClangdTypeHierarchy<cr>', desc = '[C]langd [T]ype Hierarchy' },
    { '<leader>cc', '<cmd>ClangdCallHierarchy<cr>', desc = '[C]langd [C]all Hierarchy' },
  },
}
