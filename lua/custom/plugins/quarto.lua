return {
  'quarto-dev/quarto-nvim',
  dependencies = {
    'jmbuhr/otter.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  ft = { 'quarto', 'markdown' },
  opts = {
    lspFeatures = {
      enabled = true,
      languages = { 'r', 'python', 'julia', 'bash', 'html', 'rust', 'golang' },
      chunks = 'all',
      diagnostics = { enabled = true, triggers = { 'BufWritePost' } },
      completion = { enabled = true },
    },
    codeRunner = {
      enabled = true,
      default_method = 'molten',
    },
  },
}
