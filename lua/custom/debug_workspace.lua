local M = {}
local tab

function M.open()
  local source = vim.api.nvim_get_current_buf()
  if tab and vim.api.nvim_tabpage_is_valid(tab) then
    vim.api.nvim_set_current_tabpage(tab)
  else
    vim.cmd 'tab split'
    tab = vim.api.nvim_get_current_tabpage()
    vim.api.nvim_win_set_buf(0, source)
    vim.t[tab].debug_workspace = true
  end
  require('dapui').open()
end

return M
