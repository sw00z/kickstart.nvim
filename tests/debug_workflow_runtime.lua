-- Run through tests/debug_ui_driver.py; dap-ui controls require an initialized UI.
vim.opt.rtp:prepend(vim.fn.getcwd())
for _, path in ipairs(vim.fn.glob(vim.fn.stdpath 'data' .. '/lazy/*', false, true)) do
  vim.opt.rtp:append(path)
end
vim.opt.swapfile = false
vim.o.columns, vim.o.lines = 180, 55
vim.env.PATH = '/usr/bin:' .. vim.env.PATH .. ':' .. vim.fn.stdpath 'data' .. '/mason/bin'
local root = '/tmp/nvim-debug-workflow-' .. vim.fn.getpid()
vim.fn.mkdir(root, 'p')
local stdpath = vim.fn.stdpath
vim.fn.stdpath = function(kind)
  return (kind == 'log' or kind == 'state') and root or stdpath(kind)
end
local dap = require 'dap'
dap.set_log_level 'INFO'
-- Exercise the real plugin config without invoking package installation.
package.loaded['mason-nvim-dap'] = {
  setup = function()
    dap.adapters.codelldb = {
      type = 'server',
      port = '${port}',
      executable = {
        command = stdpath 'data' .. '/mason/bin/codelldb',
        args = { '--port', '${port}' },
      },
    }
  end,
}
dofile('lua/kickstart/plugins/debug.lua').config()
vim.cmd 'checkhealth dap'
vim.fn.writefile(vim.api.nvim_buf_get_lines(0, 0, -1, false), root .. '/health.txt')
print('DAP health report: ' .. root .. '/health.txt')
local source = root .. '/main.cpp'
vim.fn.writefile({
  '#include <iostream>',
  '#include <string>',
  '#include <vector>',
  'int main(int argc, char **argv) {',
  '  std::vector<int> values{3, 7, 11};',
  '  int total = values[0] + values[1];',
  '  std::cout << "ready:" << argv[1] << std::endl;',
  '  std::string input;',
  '  if (argc > 2) input = argv[2]; else std::getline(std::cin, input);',
  '  std::cout << "read:" << input << ":" << total << std::endl;',
  '  return argc >= 2 && input == "hello debugger" && total == 10 ? 0 : 1;',
  '}',
}, source)
local out = vim.system({ '/usr/bin/clang++-21', '-std=c++23', '-g', '-O0', source, '-o', root .. '/app' }, { text = true }):wait()
assert(out.code == 0, out.stderr)
local function wait(predicate, label)
  assert(vim.wait(15000, predicate, 20), label .. '; inspect ' .. root .. '/dap.log')
end
local function request(session, method, args)
  local finished, result, failure
  session:request(method, args, function(err, body)
    finished, result, failure = true, body, err
  end)
  wait(function()
    return finished
  end, method)
  assert(not failure, vim.inspect(failure))
  return result
end
local ok, err = xpcall(function()
  for _, adapter in ipairs { 'codelldb', 'gdb', 'lldb-dap', 'codelldb' } do
    assert(require('custom.debug_native').set_backend(adapter == 'gdb' and 'gdb' or 'lldb'))
    assert(dap.adapters[adapter], 'adapter not detected: ' .. adapter)
    vim.cmd.edit(source)
    local buf = vim.api.nvim_get_current_buf()
    vim.bo.filetype = 'cpp'
    require('dap.breakpoints').clear()
    require('dap.breakpoints').set({}, buf, 7)
    local exit_code, stop_body
    local output = ''
    dap.listeners.after.event_output.runtime = function(_, body)
      output = output .. (body.output or '')
    end
    dap.listeners.before.event_stopped.stop_reason = function(_, body)
      stop_body = body
    end
    dap.listeners.before.event_exited.runtime = function(_, body)
      exit_code = body.exitCode
    end
    local config
    for _, candidate in ipairs(dap.configurations.cpp) do
      if candidate.type == adapter and candidate.request == 'launch' then
        config = vim.deepcopy(candidate)
        break
      end
    end
    assert(config)
    config.program, config.cwd, config.args = root .. '/app', root, { 'two words' }
    if adapter == 'gdb' then
      config.args[2] = 'hello debugger'
    end
    dap.run(config)
    wait(function()
      return dap.session() and dap.session().stopped_thread_id
    end, adapter .. ' breakpoint')
    local session = dap.session()
    local stack = request(session, 'stackTrace', { threadId = session.stopped_thread_id })
    local frame = stack.stackFrames[1]
    assert(frame.line == 7, 'wrong breakpoint: ' .. vim.inspect { frame = frame, stop = stop_body })
    local scopes = request(session, 'scopes', { frameId = frame.id })
    assert(#scopes.scopes > 0, 'no scopes')
    local local_scope
    for _, scope in ipairs(scopes.scopes) do
      if scope.presentationHint == 'locals' or scope.name == 'Locals' or scope.name == 'Local' then
        local_scope = scope
        break
      end
    end
    assert(local_scope, 'local scope missing: ' .. vim.inspect(scopes.scopes))
    local variables = request(session, 'variables', { variablesReference = local_scope.variablesReference })
    local total, vector
    for _, variable in ipairs(variables.variables) do
      if variable.name == 'total' then
        total = variable.value
      end
      if variable.name == 'values' then
        vector = variable
      end
    end
    assert(total == '10', 'local value unavailable: ' .. tostring(total))
    assert(vector and vector.variablesReference > 0, 'vector not expandable')
    local children = request(session, 'variables', { variablesReference = vector.variablesReference })
    assert(#children.variables > 0, 'vector children missing')
    local evaluation = request(session, 'evaluate', { expression = 'total + 1', frameId = frame.id, context = 'watch' })
    assert(evaluation.result:find('11', 1, true), 'expression evaluation')
    local stopped = 0
    dap.listeners.after.event_stopped.runtime = function()
      stopped = stopped + 1
    end
    dap.step_over()
    wait(function()
      return stopped > 0
    end, 'step over')
    local terminal
    if adapter ~= 'gdb' then
      for _, candidate in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[candidate].buftype == 'terminal' and vim.b[candidate].terminal_job_id then
          terminal = candidate
        end
      end
      assert(terminal, 'integrated program terminal missing')
      vim.api.nvim_chan_send(vim.b[terminal].terminal_job_id, 'hello debugger\n')
    end
    dap.continue()
    wait(function()
      return exit_code ~= nil
    end, 'program exit')
    assert(exit_code == 0, 'stdin or argument fidelity failed: ' .. exit_code)
    wait(function()
      return dap.session() == nil
    end, 'session cleanup')
    wait(function()
      local text = terminal and table.concat(vim.api.nvim_buf_get_lines(terminal, 0, -1, false), '\n') or output
      return text:find('ready:two words', 1, true) and text:find('read:hello debugger:10', 1, true)
    end, 'terminal output drain')
    require('dapui').close()
    dap.listeners.after.event_stopped.runtime = nil
    print('PASS ' .. adapter .. ': breakpoint, scopes, vector, evaluation, stepping, output, arguments, exit' .. (terminal and ', terminal stdin' or ''))
  end
  vim.cmd.edit(source)
  local before = #vim.api.nvim_list_tabpages()
  require('custom.debug_workspace').open()
  assert(#vim.api.nvim_list_tabpages() == before + 1, 'debug tab not created')
  require('custom.debug_workspace').open()
  assert(#vim.api.nvim_list_tabpages() == before + 1, 'duplicate debug tab')
  local widths = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
    widths[ft] = vim.api.nvim_win_get_width(win)
  end
  assert(widths.dapui_scopes == 45 and widths.cpp and widths.cpp >= 100, vim.inspect(widths))
  print 'PASS debug workspace reuses its tab and reserves at least 100 source columns at 180 columns'
end, debug.traceback)
if dap.session() then
  dap.terminate()
end
vim.fn.writefile({ ok and 'PASS GDB, both LLDB adapters, backend switching, and debug workspace' or tostring(err) }, root .. '/result.txt')
print('Debugger runtime artifacts: ' .. root)
if not ok then
  error(err)
end
