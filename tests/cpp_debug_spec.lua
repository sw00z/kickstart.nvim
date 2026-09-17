vim.opt.rtp:prepend(vim.fn.getcwd())
local skeleton = require 'custom.cpp_skeleton'
local native = require 'custom.debug_native'
local actions = require 'custom.cpp_actions'
local checks = 0
local function check(value, message)
  assert(value, message)
  checks = checks + 1
end

for _, name in ipairs { 'Widget', 'http_client', 'X7' } do
  check(skeleton.identifier(name), name)
end
for _, name in ipairs { 'class', 'my-engine', '7up', '_Reserved', 'Bad__Name', 'x\nY' } do
  check(not skeleton.identifier(name), name)
end
check(skeleton.namespace 'engine::net', 'nested namespace')
check(skeleton.namespace '', 'global namespace')
check(not skeleton.namespace 'engine::', 'empty namespace component')
local header = assert(skeleton.render { kind = 'header', class = 'Widget', namespace = 'engine::net' })
check(table.concat(header, '\n'):find('namespace engine::net', 1, true), 'namespace is explicit')
check(not skeleton.render { kind = 'source', include = 'oops"\n#error BAD' }, 'reject header injection')
check(not skeleton.render { kind = 'header', class = 'class' }, 'reject keyword class')
check(vim.deep_equal(native.parse_args '', {}), 'empty arguments')
check(vim.deep_equal(native.parse_args '[]', {}), 'empty array')
check(vim.deep_equal(native.parse_args ' ["two words", "", "a\\\\b", "$(literal)"] ', { 'two words', '', 'a\\b', '$(literal)' }), 'argument fidelity')
for _, input in ipairs { '{}', 'null', '[1]', '[false]', '[null]', '["\\u0000"]', '["unterminated]' } do
  check(native.parse_args(input) == nil, 'invalid arguments: ' .. input)
end
check(
  actions.matches(
    { title = 'Define constructor', command = { command = 'clangd.applyTweak', arguments = { { tweakID = 'MemberwiseConstructor' } } } },
    'constructor'
  ),
  'constructor selection'
)
check(not actions.matches({ title = 'Rename', command = 'rename' }, 'constructor'), 'unrelated action')

vim.cmd.enew()
vim.api.nvim_buf_set_name(0, '/tmp/skeleton-spec-Widget.hpp')
local buf = vim.api.nvim_get_current_buf()
local input, notify = vim.ui.input, vim.notify
vim.notify = function() end
local answers = { 'Widget', 'demo' }
vim.ui.input = function(_, callback)
  callback(table.remove(answers, 1))
end
skeleton.insert()
check(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == '#pragma once', 'insert into empty buffer')
local before = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
skeleton.insert()
check(vim.deep_equal(before, vim.api.nvim_buf_get_lines(buf, 0, -1, false)), 'preserve nonempty buffer')
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { '' })
vim.ui.input = function(_, callback)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { '// concurrent edit' })
  callback 'Widget'
end
skeleton.insert()
check(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == '// concurrent edit', 'reject stale prompt result')
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { '' })
vim.ui.input = function(_, callback)
  callback(nil)
end
skeleton.insert()
check(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == '', 'cancel prompt')
vim.ui.input, vim.notify = input, notify

local cwd = vim.fn.getcwd()
local root = vim.fn.tempname() .. '-debug-project'
vim.fn.mkdir(root .. '/.git', 'p')
vim.fn.mkdir(root .. '/src', 'p')
vim.fn.mkdir(root .. '/build/debug', 'p')
assert(vim.uv.fs_symlink('/usr/bin/true', root .. '/build/debug/app'))
vim.cmd.enew()
vim.api.nvim_buf_set_name(0, root .. '/src/main.cpp')
vim.bo.filetype = 'cpp'
check(native.root() == root, 'detect source root independently of cwd')
local selection, launch
local old_select, old_input, old_dap = vim.ui.select, vim.fn.input, package.loaded.dap
package.loaded.dap = {
  ABORT = {},
  run = function(config)
    launch = config
  end,
}
vim.ui.select = function(items)
  selection = items
end
vim.fn.input = function()
  return '["two words"]'
end
require('custom.debug_pick').pick()
vim.cmd.cd '/tmp'
for _, item in ipairs(selection) do
  if not item.label:match '^%[' then
    item.run()
    break
  end
end
check(launch and launch.cwd == root, 'picker preserves root after cwd changes')
check(launch.program == root .. '/build/debug/app', 'scan nested Debug output')
check(vim.deep_equal(launch.args, { 'two words' }), 'picker uses lossless arguments')
check(launch.terminal == 'integrated', 'picker requests program terminal')
vim.fn.input = function()
  return ''
end
check(native.program() == package.loaded.dap.ABORT, 'cancel executable selection')
vim.ui.select, vim.fn.input, package.loaded.dap = old_select, old_input, old_dap
vim.cmd.cd(cwd)
print(('PASS %d C++ / debugger regression checks'):format(checks))
