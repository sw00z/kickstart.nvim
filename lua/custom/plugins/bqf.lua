-- nvim-bqf: preview, fzf filter and signs for the native quickfix and location list windows.
-- Loads on the qf filetype, so every source gets it: telescope <C-q>, grr, <leader>Q, :grep.
return {
  'kevinhwang91/nvim-bqf',
  ft = 'qf',
  opts = {
    preview = {
      -- The preview loads each file the cursor passes over; skip files above 100 KiB.
      should_preview_cb = function(bufnr)
        return vim.fn.getfsize(vim.api.nvim_buf_get_name(bufnr)) <= 100 * 1024
      end,
    },
  },
}
