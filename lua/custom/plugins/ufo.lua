-- nvim-ufo: folds from treesitter (indent fallback), with the folded line count as fold text.
-- ufo forces foldmethod=manual, so aerial.nvim keeps manage_folds = false.
-- <leader>vz (aerial.lua) closes these folds by aerial symbol kind.

-- The first line keeps its syntax highlights; the suffix shows how many lines are hidden.
local function fold_text(virt_text, lnum, end_lnum, width, truncate)
  local result = {}
  local suffix = ('  󰁂 %d '):format(end_lnum - lnum)
  local target_width = width - vim.fn.strdisplaywidth(suffix)
  local cur_width = 0
  for _, chunk in ipairs(virt_text) do
    local text, hl = chunk[1], chunk[2]
    local chunk_width = vim.fn.strdisplaywidth(text)
    if cur_width + chunk_width < target_width then
      table.insert(result, chunk)
    else
      text = truncate(text, target_width - cur_width)
      table.insert(result, { text, hl })
      chunk_width = vim.fn.strdisplaywidth(text)
      -- truncate() can return fewer cells than requested; pad so the suffix stays right of the text.
      if cur_width + chunk_width < target_width then
        suffix = suffix .. (' '):rep(target_width - cur_width - chunk_width)
      end
      break
    end
    cur_width = cur_width + chunk_width
  end
  table.insert(result, { suffix, 'MoreMsg' })
  return result
end

return {
  'kevinhwang91/nvim-ufo',
  dependencies = { 'kevinhwang91/promise-async' },
  event = 'VeryLazy',
  init = function()
    -- ufo closes folds with commands, not by level; a low foldlevel would close everything on open.
    vim.o.foldlevel = 99
    vim.o.foldlevelstart = 99
    vim.o.foldenable = true
  end,
  -- Native zr/zm/zR/zM rewrite foldlevel, which reopens or recloses every fold; these keep it at 99.
  -- stylua: ignore
  keys = {
    { 'zR', function() require('ufo').openAllFolds() end, desc = 'Open all folds' },
    { 'zM', function() require('ufo').closeAllFolds() end, desc = 'Close all folds' },
    { 'zr', function() require('ufo').openFoldsExceptKinds() end, desc = 'Open folds' },
    { 'zm', function() require('ufo').closeFoldsWith() end, desc = 'Close folds deeper than count' },
    { 'zK', function() require('ufo').peekFoldedLinesUnderCursor() end, desc = 'Peek folded lines' },
  },
  opts = {
    -- File buffers only; panels, terminals and help keep no folds.
    provider_selector = function(_, _, buftype)
      return buftype == '' and { 'treesitter', 'indent' } or ''
    end,
    fold_virt_text_handler = fold_text,
  },
}
