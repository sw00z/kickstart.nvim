-- nvim --headless -u NONE -i NONE -l tests/cpp_workflow_runtime.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
vim.opt.swapfile = false
local root = '/tmp/nvim-cpp-workflow-' .. vim.fn.getpid()
vim.fn.mkdir(root, 'p')
local stdpath = vim.fn.stdpath
vim.fn.stdpath = function(kind)
  return (kind == 'log' or kind == 'state') and root or stdpath(kind)
end
vim.lsp.set_log_level 'ERROR'
local clients = {}
local function write(name, lines)
  vim.fn.writefile(lines, root .. '/' .. name)
  return root .. '/' .. name
end
local function compile(source)
  local out = vim.system({ '/usr/bin/clang++-21', '-std=c++23', '-g', '-O0', '-I' .. root, source, '-o', root .. '/app' }, { text = true }):wait()
  assert(out.code == 0, out.stderr)
  local run = vim.system({ root .. '/app' }, { text = true }):wait()
  assert(run.code == 0, run.stderr)
end
local function open(name, lines)
  local path = write(name, lines)
  vim.cmd.edit(path)
  vim.bo.filetype = 'cpp'
  local buf = vim.api.nvim_get_current_buf()
  local id = vim.lsp.start {
    name = 'clangd',
    cmd = { '/usr/bin/clangd-21', '--enable-config', '--background-index=false' },
    root_dir = root,
    init_options = { fallbackFlags = { '-std=c++23', '-I' .. root } },
  }
  local client = assert(vim.lsp.get_client_by_id(id))
  clients[id] = client
  assert(
    vim.wait(10000, function()
      return client.initialized
    end, 20),
    'clangd initialization'
  )
  return client, buf
end
local function request(client, buf, row, col)
  vim.api.nvim_win_set_cursor(0, { row, col })
  local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
  params.context = { diagnostics = {} }
  local response = client:request_sync('textDocument/codeAction', params, 10000, buf)
  assert(response and not response.err, vim.inspect(response))
  return response.result or {}
end
local function apply(client, buf, action)
  if action.edit then
    vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
  end
  if action.command then
    local result = client:request_sync('workspace/executeCommand', action.command, 10000, buf)
    assert(result and not result.err, vim.inspect(result))
  end
end
local function find_action(client, buf, row, col, kind)
  local result
  assert(
    vim.wait(10000, function()
      for _, action in ipairs(request(client, buf, row, col)) do
        if require('custom.cpp_actions').matches(action, kind) then
          result = action
          return true
        end
      end
    end, 100),
    'Missing clangd action: ' .. kind
  )
  return result
end
local ok, err = xpcall(function()
  local skeleton = require 'custom.cpp_skeleton'
  write('Widget.hpp', assert(skeleton.render { kind = 'header', class = 'Widget', namespace = 'example::net' }))
  local main = write('main.cpp', { '#include "Widget.hpp"', 'int main() { example::net::Widget item; return 0; }' })
  compile(main)
  print 'PASS skeleton compiles with an explicit nested namespace'
  local client, buf = open('Member.hpp', {
    '#pragma once',
    '#include <string>',
    '#include <memory>',
    '#include <utility>',
    'struct Member {',
    '  int count;',
    '  std::string name;',
    '  std::unique_ptr<int> pointer;',
    '};',
  })
  apply(client, buf, find_action(client, buf, 5, 8, 'constructor'))
  local generated = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  assert(table.concat(generated, '\n'):find('std::move', 1, true), 'move-only member must move')
  write('Member.hpp', generated)
  main = write('main.cpp', { '#include "Member.hpp"', 'int main() { Member item(3, "Ada", std::make_unique<int>(7)); return *item.pointer != 7; }' })
  compile(main)
  print 'PASS clangd constructor compiles and initializes a move-only member'
  write('Extract.cpp', { '#include "Extract.hpp"' })
  client, buf = open('Extract.hpp', { '#pragma once', 'namespace demo {', 'class Extract {', 'public:', '  int value() const { return 7; }', '};', '}' })
  apply(client, buf, find_action(client, buf, 5, 8, 'outline'))
  local declaration = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n')
  assert(not declaration:find('return 7', 1, true), 'body removed from header')
  write('Extract.hpp', vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  local source_buf = vim.fn.bufnr(root .. '/Extract.cpp')
  assert(source_buf ~= -1, 'source buffer edited')
  local definition = vim.api.nvim_buf_get_lines(source_buf, 0, -1, false)
  assert(table.concat(definition, '\n'):find('return 7', 1, true), 'body in source')
  definition[#definition + 1] = 'int main() { return demo::Extract().value() != 7; }'
  compile(write('Extract.cpp', definition))
  print 'PASS clangd extraction edits both buffers and the linked result runs'
  write('Inline.hpp', { '#pragma once', 'struct Inline { int value() const; };' })
  client, buf = open('Inline.cpp', { '#include "Inline.hpp"', 'int Inline::value() const { return 9; }' })
  apply(client, buf, find_action(client, buf, 2, 13, 'inline'))
  local inline_header = vim.fn.bufnr(root .. '/Inline.hpp')
  assert(inline_header ~= -1, 'inline destination buffer missing')
  local inline_lines = vim.api.nvim_buf_get_lines(inline_header, 0, -1, false)
  assert(table.concat(inline_lines, '\n'):find('return 9', 1, true), 'definition not moved into header')
  write('Inline.hpp', inline_lines)
  local inline_source = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  assert(not table.concat(inline_source, '\n'):find('return 9', 1, true), 'old out-of-line definition remains')
  inline_source[#inline_source + 1] = 'int main() { return Inline().value() != 9; }'
  compile(write('Inline.cpp', inline_source))
  print 'PASS clangd inverse extraction moves the definition inline and the result runs'
  client, buf = open('includes.cpp', { '#include <vector>', 'int main() { return 0; }' })
  assert(
    vim.wait(10000, function()
      return #vim.diagnostic.get(buf) > 0
    end, 50),
    'unused include diagnostic'
  )
  local select = vim.ui.select
  vim.ui.select = function(items, _, callback)
    callback(items[1])
  end
  vim.api.nvim_win_set_cursor(0, { 2, 4 })
  require('custom.cpp_actions').run 'includes'
  assert(
    vim.wait(10000, function()
      return not table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n'):find('#include', 1, true)
    end, 20),
    'whole-file include action did not remove diagnostic away from cursor'
  )
  vim.ui.select = select
  print 'PASS CppIncludes removes an unused header while the cursor is elsewhere'
end, debug.traceback)
for _, client in pairs(clients) do
  client:stop(true)
end
print('C++ runtime artifacts: ' .. root)
if not ok then
  error(err)
end
