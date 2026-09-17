vim.opt.rtp:prepend(vim.fn.getcwd())
vim.opt.swapfile = false
vim.env.PATH = '/usr/bin:' .. vim.env.PATH
local root = vim.fn.tempname() .. '-debug-build'
vim.fn.mkdir(root, 'p')
vim.fn.writefile({
  'cmake_minimum_required(VERSION 3.20)',
  'set(CMAKE_CXX_COMPILER /usr/bin/clang++-21)',
  'project(DebugFixture LANGUAGES CXX)',
  'add_executable(app main.cpp)',
}, root .. '/CMakeLists.txt')
local source = root .. '/main.cpp'
vim.fn.writefile({ 'int main() { return 0; }' }, source)
vim.cmd.edit(source)
vim.bo.filetype = 'cpp'
local launched, failed
package.loaded.dap = {
  ABORT = {},
  run = function(config)
    launched = config
  end,
}
vim.fn.input = function()
  return '[]'
end
vim.notify = function(message)
  if message:find('Build failed', 1, true) then
    failed = message
  end
end
vim.ui.select = function(items, _, callback)
  for _, item in ipairs(items) do
    if type(item) == 'table' and item.label:find('[build project', 1, true) then
      callback(item)
      return
    end
  end
  error 'build action missing'
end
require('custom.debug_pick').pick()
vim.cmd.cd '/tmp'
assert(
  vim.wait(30000, function()
    return launched or failed
  end, 50),
  'build timed out'
)
assert(not failed, failed)
assert(launched.cwd == root, 'async build lost root')
assert(launched.program == root .. '/build/debug/app', 'wrong executable')
assert(vim.fn.filereadable(root .. '/build/debug/compile_commands.json') == 1, 'compile database missing')
print 'PASS CMake configure/build selects build/debug and preserves root across cwd changes'

launched, failed = nil, nil
vim.fn.writefile({ '#error Intentional build failure' }, source)
require('custom.debug_pick').pick()
assert(
  vim.wait(30000, function()
    return launched or failed
  end, 50),
  'failing rebuild timed out'
)
assert(failed and not launched, 'failed build launched a stale executable')
print 'PASS failed rebuild never launches the previous executable'
print('Build runtime artifacts: ' .. root)
