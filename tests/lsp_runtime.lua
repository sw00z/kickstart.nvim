-- Run from this configuration: nvim --headless -u NONE -i NONE -l tests/lsp_runtime.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
for _, path in ipairs(vim.fn.glob(vim.fn.stdpath 'data' .. '/lazy/*', false, true)) do
  vim.opt.rtp:append(path)
end
vim.env.PATH = vim.env.PATH .. ':' .. vim.fn.stdpath 'data' .. '/mason/bin'
vim.env.GOPROXY = 'off'
vim.env.GOTOOLCHAIN = 'local'
vim.opt.swapfile = false
local state = '/tmp/nvim-lsp-runtime-' .. vim.fn.getpid()
vim.fn.mkdir(state, 'p')
vim.env.NVIM_LOG_FILE = state .. '/nvim.log'
local stdpath = vim.fn.stdpath
vim.fn.stdpath = function(kind)
  return (kind == 'state' or kind == 'log') and state or stdpath(kind)
end
vim.lsp.set_log_level 'debug'
print('Runtime log: ' .. vim.lsp.log.get_filename())
package.loaded['mason-tool-installer'] = { setup = function() end }
package.loaded['mason-lspconfig'] = { setup = function() end }
dofile('lua/kickstart/plugins/lspconfig.lua')[2].config()

local function start(name, root, path, ft, lines)
  vim.cmd.enew()
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(buf, path)
  if lines then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  else
    vim.cmd.edit(path)
  end
  vim.bo.filetype = ft
  local config = vim.deepcopy(vim.lsp.config[name])
  config.name, config.root_dir = name, root
  if name == 'ts_ls' then
    config.init_options.tsserver = { logVerbosity = 'verbose', logDirectory = state }
  end
  if name == 'ts_ls' then
    print('TS launcher: ' .. vim.fn.exepath 'typescript-language-server')
  end
  local began = vim.uv.hrtime()
  local id = assert(vim.lsp.start(config, { bufnr = buf }))
  assert(
    vim.wait(25000, function()
      local client = vim.lsp.get_client_by_id(id)
      return client and client.initialized
    end, 50),
    name .. ' initialization timed out'
  )
  local client = assert(vim.lsp.get_client_by_id(id))
  print(('%s initialize: %.0f ms; root=%s'):format(name, (vim.uv.hrtime() - began) / 1e6, root))
  return client, buf
end

local function position(client, buf, row, column)
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_win_set_cursor(0, { row, column })
  return vim.lsp.util.make_position_params(0, client.offset_encoding)
end
local function request(client, buf, method, params)
  local began = vim.uv.hrtime()
  local response, err = client:request_sync(method, params, 20000, buf)
  assert(response and not response.err, vim.inspect(err or response))
  print(('%s %s: %.0f ms'):format(client.name, method, (vim.uv.hrtime() - began) / 1e6))
  return response.result
end

local clients = {}
local ok, err = xpcall(function()
  local fleet = vim.fn.expand '~/projects/fleetwise-technologies/serverless-setup/fleetwise'
  for _, app in ipairs { 'rental-booking', 'fleetwise-home' } do
    local root = fleet .. '/apps/' .. app
    -- Existing paths participate in tsconfig include discovery; contents stay unsaved.
    local path = root .. '/client/src/App.tsx'
    local client, buf = start('ts_ls', root, path, 'typescriptreact', {
      'import { useState } from "react";',
      'const [value, setValue] = useState<number>(1);',
      'console.log(value);',
      'import { cn } from "@/lib/utils";',
      'console.log(cn("test"));',
      'useE',
    })
    clients[#clients + 1] = client
    local began = vim.uv.hrtime()
    local ready = false
    for _ = 1, 60 do
      local response = client:request_sync('textDocument/hover', position(client, buf, 2, 29), 5000, buf)
      local hover = response and response.result
      ready = hover and hover.contents and vim.inspect(hover.contents):find('SetStateAction', 1, true) ~= nil
      if ready then
        break
      end
      vim.wait(500)
    end
    assert(ready, 'React semantic project did not finish loading')
    print(('React semantic hover ready: %.0f ms'):format((vim.uv.hrtime() - began) / 1e6))
    assert(vim.uv.fs_realpath(client.config.init_options.tsserver.path):find('/fleetwise/node_modules/', 1, true), 'Project TypeScript SDK not selected')
    local definition = request(client, buf, 'textDocument/definition', position(client, buf, 1, 12))
    assert(definition and #definition > 0, 'React definition missing')
    local uri = definition[1].uri or definition[1].targetUri
    assert(vim.uri_to_fname(uri):find(app == 'rental-booking' and 'react@18' or 'react@19', 1, true), 'Wrong React declarations: ' .. uri)
    assert(vim.fn.exists ':LspTypescriptGoToSourceDefinition' == 2)
    local alias = request(client, buf, 'textDocument/definition', position(client, buf, 4, 10))
    assert(
      alias and #alias > 0 and vim.uri_to_fname(alias[1].uri or alias[1].targetUri) == root .. '/client/src/lib/utils.ts',
      'Package alias resolved incorrectly'
    )
    local completions = request(client, buf, 'textDocument/completion', position(client, buf, 6, 4))
    local auto_import
    for _, entry in ipairs(completions.items or completions) do
      if entry.label == 'useEffect' then
        auto_import = entry
        break
      end
    end
    assert(auto_import, 'React auto-import candidate missing')
    local resolved = request(client, buf, 'completionItem/resolve', auto_import)
    assert(resolved and resolved.additionalTextEdits and #resolved.additionalTextEdits > 0, 'React import edit missing')
    assert(require('custom.lsp_profiles').set(root, 'balanced'))
    assert(not vim.lsp.inlay_hint.is_enabled { bufnr = buf })
    request(client, buf, 'textDocument/hover', position(client, buf, 2, 29))
    vim.bo[buf].modified = false
  end

  local go_root = vim.fn.expand '~/projects/fleetwise-technologies/hertz-scrape'
  local go, go_buf = start('gopls', go_root, go_root .. '/nvim_probe.go', 'go', {
    'package main',
    'import "github.com/PuerkitoBio/goquery"',
    'func nvimProbe(s *goquery.Selection) int { return s.Length() }',
  })
  clients[#clients + 1] = go
  local hover = request(go, go_buf, 'textDocument/hover', position(go, go_buf, 3, 52))
  assert(hover and hover.contents, 'goquery hover missing')
  local docs_params = vim.lsp.util.make_range_params(0, go.offset_encoding)
  docs_params.context = { only = { 'source.doc' }, diagnostics = {} }
  local actions = request(go, go_buf, 'textDocument/codeAction', docs_params)
  assert(actions and #actions > 0, 'gopls package documentation action missing')
  request(go, go_buf, 'textDocument/hover', position(go, go_buf, 3, 52))
  assert(require('custom.lsp_profiles').set(go_root, 'balanced'))
  assert(go.settings.gopls.staticcheck == false, 'Live Go profile not updated')
  assert(not vim.lsp.inlay_hint.is_enabled { bufnr = go_buf })
  request(go, go_buf, 'textDocument/hover', position(go, go_buf, 3, 52))
  vim.bo[go_buf].modified = false

  local cpp_root = state .. '/cpp'
  vim.fn.mkdir(cpp_root, 'p')
  local cpp, cpp_buf = start('clangd', cpp_root, cpp_root .. '/probe.cpp', 'cpp', {
    '#include <vector>',
    'namespace a { int make(int); int make(double); }',
    'namespace b { double make(double); }',
    'int main() { std::vector<int> values; values.push_back(1); a::make(1); }',
  })
  clients[#clients + 1] = cpp
  assert(vim.wait(10000, function()
    return next(vim.lsp.get_clients { bufnr = cpp_buf }) ~= nil
  end, 50))
  local result = request(cpp, cpp_buf, 'textDocument/hover', position(cpp, cpp_buf, 4, 45))
  assert(result and result.contents, 'C++ hover missing')
  local params = position(cpp, cpp_buf, 4, 60)
  local completion = request(cpp, cpp_buf, 'textDocument/completion', params)
  assert(completion and #completion.items > 0, 'C++ completions missing')
  local grouped = require('custom.cmp_clangd_overloads').group(vim.deepcopy(completion), cpp.server_capabilities.completionProvider.resolveProvider)
  for _, candidate in ipairs(grouped.items) do
    assert(
      vim.iter(completion.items):any(function(original)
        return vim.deep_equal(candidate.textEdit, original.textEdit) and vim.deep_equal(candidate.additionalTextEdits, original.additionalTextEdits)
      end),
      'Grouping changed actual clangd edits'
    )
  end
  print(('C++ candidates: %d native, %d safe groups'):format(#completion.items, #grouped.items))
  request(cpp, cpp_buf, 'textDocument/completion', params)
  assert(require('custom.lsp_profiles').set(cpp_root, 'balanced'))
  assert(
    vim.wait(15000, function()
      for _, client in ipairs(vim.lsp.get_clients { bufnr = cpp_buf, name = 'clangd' }) do
        if client.id ~= cpp.id and client.initialized then
          cpp = client
          return true
        end
      end
      return false
    end, 50),
    'clangd profile restart failed'
  )
  assert(vim.tbl_contains(cpp.config._resolved_command, '-j=2'))
  assert(vim.bo[cpp_buf].modified, 'Restart lost unsaved buffer state')
  request(cpp, cpp_buf, 'textDocument/hover', position(cpp, cpp_buf, 4, 45))
  request(cpp, cpp_buf, 'textDocument/completion', position(cpp, cpp_buf, 4, 60))
  clients[#clients + 1] = cpp
  vim.bo[cpp_buf].modified = false
  vim.fn.mkdir(state .. '/c', 'p')
  local c, c_buf = start('clangd', state .. '/c', state .. '/c/probe.c', 'c', {
    '#include <stddef.h>',
    'size_t probe(const char *text) { return sizeof(text); }',
  })
  local c_hover = request(c, c_buf, 'textDocument/hover', position(c, c_buf, 2, 2))
  assert(c_hover and c_hover.contents, 'C standard-library hover missing')
  vim.bo[c_buf].modified = false
  local conform_opts = dofile('lua/kickstart/plugins/conform.lua')[1].opts
  conform_opts.format_on_save = nil
  require('conform').setup(conform_opts)
  local format_root = state .. '/format'
  vim.fn.mkdir(format_root, 'p')
  vim.fn.writefile({ '{"prettier":{"singleQuote":true,"semi":false}}' }, format_root .. '/package.json')
  vim.cmd.enew()
  vim.api.nvim_buf_set_name(0, format_root .. '/probe.ts')
  vim.bo.filetype = 'typescript'
  local input = { 'const message="hello";' }
  local expected = { "const message = 'hello'" }
  for _, formatter in ipairs { 'prettier', 'prettierd' } do
    vim.api.nvim_buf_set_lines(0, 0, -1, false, input)
    local failure
    require('conform').format({ async = false, timeout_ms = 5000, formatters = { formatter } }, function(format_err)
      failure = format_err
    end)
    assert(not failure, tostring(failure))
    assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), expected), formatter .. ' ignored package.json configuration')
  end
  vim.bo.modified = false
  vim.cmd.enew()
  vim.api.nvim_buf_set_name(0, format_root .. '/probe.go')
  vim.fn.writefile({ 'module nvimprobe', '', 'go 1.24.0' }, format_root .. '/go.mod')
  vim.bo.filetype = 'go'
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'package main', 'func probe( ){fmt.Println("x")}' })
  local go_format_error
  require('conform').format({ async = false, timeout_ms = 5000 }, function(e)
    go_format_error = e
  end)
  assert(not go_format_error, tostring(go_format_error))
  assert(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n'):find('import "fmt"', 1, true), 'Go formatter did not organize imports')
  print 'PASS real TypeScript/React, Go documentation, C/C++ completion, project profiles and formatter ownership'
end, debug.traceback)

for _, client in ipairs(vim.lsp.get_clients()) do
  client:stop()
end
vim.wait(1000, function()
  return #vim.lsp.get_clients() == 0
end, 50)
if not ok then
  error(err)
end
vim.cmd 'qa!'
