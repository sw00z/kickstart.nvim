-- csvview.nvim: aligned column view for CSV/TSV buffers. Loads only for those
-- filetypes and auto-enables the view on open, so columns line up without a
-- manual command. Toggle off/on with <leader>vc.
return {
  'hat0uma/csvview.nvim',
  ft = { 'csv', 'tsv' },
  cmd = { 'CsvViewEnable', 'CsvViewDisable', 'CsvViewToggle' },
  keys = {
    { '<leader>vc', '<cmd>CsvViewToggle<CR>', desc = 'Toggle [V]iew: [C]SV columns' },
  },
  opts = {
    parser = { comments = { '#', '//' } },
    view = {
      display_mode = 'border', -- draw column separators as vertical borders
    },
    keymaps = {
      -- field text objects + tab-jump between fields, buffer-local to CSV views
      textobject_field_inner = { 'if', mode = { 'o', 'x' } },
      textobject_field_outer = { 'af', mode = { 'o', 'x' } },
      jump_next_field_end = { '<Tab>', mode = { 'n', 'v' } },
      jump_prev_field_end = { '<S-Tab>', mode = { 'n', 'v' } },
    },
  },
  config = function(_, opts)
    require('csvview').setup(opts)
    -- Auto-enable the aligned view whenever a CSV/TSV buffer opens.
    vim.api.nvim_create_autocmd('FileType', {
      pattern = { 'csv', 'tsv' },
      callback = function()
        vim.cmd 'CsvViewEnable'
      end,
    })
  end,
}
