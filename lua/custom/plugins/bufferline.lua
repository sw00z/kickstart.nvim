-- bufferline.nvim: buffers as sloped tabs across the top (laststatus=3 +
-- showtabline). Features wired per request:
--   * slope-shaped separators            (separator_style = 'slope')
--   * hover events                       (options.hover)
--   * LSP diagnostic indicators          (diagnostics = 'nvim_lsp')
--   * unique names for same-file basenames (show_duplicate_prefix)
--   * re-ordering                        (BufferLineMoveNext/Prev → <leader>b>/<)
--   * picking                            (BufferLinePick → <leader>bp)
--
-- The `offsets` block reserves tabline width above the neo-tree sidebar so tabs
-- begin past the docked left column instead of being drawn over it.
return {
  'akinsho/bufferline.nvim',
  version = '*',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  event = 'VeryLazy',
  keys = {
    { ']b', '<cmd>BufferLineCycleNext<CR>', desc = 'Next buffer' },
    { '[b', '<cmd>BufferLineCyclePrev<CR>', desc = 'Prev buffer' },
    { '<leader>bp', '<cmd>BufferLinePick<CR>', desc = '[P]ick buffer' },
    { '<leader>bc', '<cmd>BufferLinePickClose<CR>', desc = 'Pick + [c]lose buffer' },
    { '<leader>b>', '<cmd>BufferLineMoveNext<CR>', desc = 'Move buffer right' },
    { '<leader>b<', '<cmd>BufferLineMovePrev<CR>', desc = 'Move buffer left' },
    { '<leader>bo', '<cmd>BufferLineCloseOthers<CR>', desc = 'Close [o]ther buffers' },
    { '<leader>bP', '<cmd>BufferLineTogglePin<CR>', desc = '[P]in/unpin buffer' },
    {
      '<leader>bd',
      function()
        Snacks.bufdelete()
      end,
      desc = '[D]elete buffer (keep window)',
    },
  },
  opts = {
    options = {
      mode = 'buffers',
      -- LSP diagnostic counts on each tab.
      diagnostics = 'nvim_lsp',
      diagnostics_indicator = function(count, level)
        local icon = level:match 'error' and ' ' or ' '
        return ' ' .. icon .. count
      end,
      -- Sloped tab edges.
      separator_style = 'slope',
      -- Hover over a tab to reveal its close button.
      hover = {
        enabled = true,
        delay = 150,
        reveal = { 'close' },
      },
      -- Disambiguate identically-named files by showing a path prefix.
      show_duplicate_prefix = true,
      -- Keep tabs clear of the docked neo-tree column.
      offsets = {
        {
          filetype = 'neo-tree',
          text = 'File Explorer',
          highlight = 'Directory',
          text_align = 'left',
          separator = true,
        },
      },
    },
  },
}
