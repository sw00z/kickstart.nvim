return {
  {
    'nyoom-engineering/oxocarbon.nvim',
    enabled = false,
    priority = 1000,
    config = function()
      require('oxocarbon').setup {}

      vim.opt.background = 'dark'

      vim.cmd.colorschemes 'oxocarbon'

      vim.api.nvim_set_hl(0, 'Normal', { bg = 'none' })
      vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'none' })
      vim.api.nvim_set_hl(0, 'NormalNC', { bg = 'none' })
    end,
  },
}
