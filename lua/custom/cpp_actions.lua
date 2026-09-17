local M = {}

local tweaks = {
  constructor = { MemberwiseConstructor = true },
  outline = { DefineOutline = true },
  inline = { DefineInline = true },
}

function M.matches(action, kind)
  if kind == 'includes' then
    return action.title:lower():find('include', 1, true) ~= nil
  end
  local cmd = action.command
  if type(cmd) ~= 'table' then
    return false
  end
  local argument = cmd.arguments and cmd.arguments[1]
  return cmd.command == 'clangd.applyTweak' and argument and tweaks[kind][argument.tweakID] == true or false
end

function M.run(kind)
  if #vim.lsp.get_clients { bufnr = 0, name = 'clangd' } == 0 then
    vim.notify('Attach clangd first; inspect :LspInfo and :LspContext', vim.log.levels.WARN)
    return
  end
  local opts = {
    filter = function(action)
      return M.matches(action, kind)
    end,
    apply = false,
  }
  if kind == 'includes' then
    opts.range = { start = { 1, 0 }, ['end'] = { vim.api.nvim_buf_line_count(0), 0 } }
    opts.context = { diagnostics = {} }
    for _, client in ipairs(vim.lsp.get_clients { bufnr = 0, name = 'clangd' }) do
      for _, pull in ipairs { false, true } do
        local ns = vim.lsp.diagnostic.get_namespace(client.id, pull)
        for _, diagnostic in ipairs(vim.diagnostic.get(0, { namespace = ns })) do
          local lsp = diagnostic.user_data and diagnostic.user_data.lsp
          if lsp then
            opts.context.diagnostics[#opts.context.diagnostics + 1] = lsp
          end
        end
      end
    end
  end
  vim.lsp.buf.code_action(opts)
end

function M.setup()
  for command, kind in pairs { CppConstructor = 'constructor', CppExtract = 'outline', CppInline = 'inline', CppIncludes = 'includes' } do
    vim.api.nvim_create_user_command(command, function()
      M.run(kind)
    end, { desc = 'C++: ' .. kind })
  end
  vim.api.nvim_create_user_command('Skel', function()
    require('custom.cpp_skeleton').insert()
  end, { desc = 'Insert a C++ skeleton into an empty buffer' })
end

return M
