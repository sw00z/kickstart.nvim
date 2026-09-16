local M = {}

function M.refresh(bufnr, excluded, reset_hints)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local group = vim.api.nvim_create_augroup('custom-lsp-buffer-' .. bufnr, { clear = true })
  local supported = {}
  for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
    if client.id ~= excluded then
      for _, method in ipairs { 'documentHighlight', 'inlayHint', 'codeLens' } do
        supported[method] = supported[method] or client:supports_method('textDocument/' .. method, bufnr)
      end
    end
  end
  local full = require('custom.lsp_profiles').for_buffer(bufnr) == 'full'
  if supported.documentHighlight then
    vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
      buffer = bufnr,
      group = group,
      callback = vim.lsp.buf.document_highlight,
    })
    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
      buffer = bufnr,
      group = group,
      callback = vim.lsp.buf.clear_references,
    })
  else
    vim.api.nvim_buf_call(bufnr, vim.lsp.buf.clear_references)
  end
  if supported.inlayHint then
    if reset_hints or not vim.b[bufnr].lsp_hints_initialized then
      vim.lsp.inlay_hint.enable(full, { bufnr = bufnr })
      vim.b[bufnr].lsp_hints_initialized = true
    end
    vim.keymap.set('n', '<leader>Lh', function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = bufnr }, { bufnr = bufnr })
    end, { buffer = bufnr, desc = 'LSP: Toggle inlay hints' })
  else
    vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
    vim.b[bufnr].lsp_hints_initialized = nil
  end
  if supported.codeLens then
    if full then
      vim.lsp.codelens.refresh { bufnr = bufnr }
      vim.api.nvim_create_autocmd('BufWritePost', {
        buffer = bufnr,
        group = group,
        callback = function()
          vim.lsp.codelens.refresh { bufnr = bufnr }
        end,
      })
    end
    vim.keymap.set('n', '<leader>Lc', vim.lsp.codelens.run, { buffer = bufnr, desc = 'LSP: Run CodeLens' })
    vim.keymap.set('n', '<leader>LC', function()
      vim.lsp.codelens.refresh { bufnr = bufnr }
    end, { buffer = bufnr, desc = 'LSP: Refresh CodeLens' })
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup('custom-lsp-lifecycle', { clear = true })
  vim.api.nvim_create_autocmd('LspDetach', {
    group = group,
    callback = function(event)
      vim.schedule(function()
        M.refresh(event.buf, event.data.client_id)
      end)
    end,
  })
  vim.api.nvim_create_autocmd('BufWipeout', {
    group = group,
    callback = function(event)
      pcall(vim.api.nvim_del_augroup_by_name, 'custom-lsp-buffer-' .. event.buf)
    end,
  })
end

return M
