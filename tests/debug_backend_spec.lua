vim.opt.rtp:prepend(vim.fn.getcwd())
local sessions, launched = {}, nil
local dap = {
  adapters = { codelldb = {}, ['lldb-dap'] = {}, gdb = {} },
  sessions = function()
    return sessions
  end,
  run = function(config)
    launched = config
  end,
  ABORT = {},
}
package.loaded.dap = dap
package.loaded['dap.utils'] = {
  pick_process = function()
    return 123
  end,
}
vim.notify = function() end
local native = require 'custom.debug_native'
local c = native.configurations()
local rust = native.configurations('target/debug/', 'rust')
assert(native.backend() == 'lldb' and c[1].type == 'codelldb')
assert(native.set_backend 'gdb')
assert(c[1].type == 'gdb' and c[2].type == 'gdb', 'launch and attach must switch')
assert(c[1].terminal == nil and c[1].runInTerminal == nil and c[1].initCommands == nil, 'LLDB launch fields leaked into GDB')
assert(rust[1].sourceLanguages == nil, 'CodeLLDB field leaked into GDB')
assert(c[3].type == 'lldb-dap', 'explicit LLVM profile was changed')
sessions[42] = {}
assert(not native.set_backend 'toggle', 'must not switch during a session')
assert(native.backend() == 'gdb')
sessions = {}
assert(native.set_backend 'toggle')
assert(c[1].type == 'codelldb' and c[1].terminal == 'integrated')
assert(rust[1].sourceLanguages[1] == 'rust', 'Rust LLDB options were not restored')
dap.adapters.gdb = nil
assert(not native.set_backend 'gdb', 'missing GDB must not change selection')
assert(native.backend() == 'lldb')
dap.adapters.gdb = {}
assert(not native.set_backend 'unknown')
native.setup()
vim.cmd 'DebugBackend gdb'
assert(native.backend() == 'gdb', 'command did not select GDB')
vim.cmd 'DebugBackend'
assert(native.backend() == 'gdb', 'status command changed selection')
vim.cmd 'DebugBackend toggle'
assert(native.backend() == 'lldb', 'command did not toggle back to LLDB')
print 'PASS backend switching, launch/attach updates, active-session guard, missing adapter, and LLDB option restoration'

local root = vim.fn.tempname() .. '-gdb-picker'
vim.fn.mkdir(root .. '/build', 'p')
vim.fn.mkdir(root .. '/.git', 'p')
assert(vim.uv.fs_symlink('/usr/bin/true', root .. '/build/app'))
vim.cmd.enew()
vim.api.nvim_buf_set_name(0, root .. '/main.cpp')
vim.bo.filetype = 'cpp'
vim.fn.input = function()
  return '[]'
end
vim.ui.select = function(items, _, callback)
  for _, item in ipairs(items) do
    if not item.label:match '^%[' then
      callback(item)
      return
    end
  end
end
assert(native.set_backend 'gdb')
require('custom.debug_pick').pick()
assert(launched and launched.type == 'gdb' and launched.terminal == nil, 'picker ignored GDB selection')
assert(native.set_backend 'lldb')
require('custom.debug_pick').pick()
assert(launched.type == 'codelldb' and launched.terminal == 'integrated', 'picker ignored LLDB selection')
print 'PASS target picker follows GDB / LLDB toggles'
