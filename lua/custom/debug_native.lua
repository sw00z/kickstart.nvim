local M = {}
local backend = 'lldb'
local profiles = {}

function M.backend()
  return backend
end

function M.adapter()
  return backend == 'gdb' and 'gdb' or 'codelldb'
end

function M.launch_options(adapter, language)
  local options = { type = adapter, stopOnEntry = false }
  if adapter == 'codelldb' then
    options.terminal = 'integrated'
    if language == 'rust' then
      options.sourceLanguages = { 'rust' }
    end
  elseif adapter == 'lldb-dap' then
    options.runInTerminal = true
    -- Resizing the program terminal must not interrupt source debugging.
    if vim.fn.has 'win32' == 0 then
      options.initCommands = { 'process handle SIGWINCH -s false -n false -p true' }
    end
  end
  return options
end

function M.set_backend(value)
  if value == 'toggle' then
    value = backend == 'lldb' and 'gdb' or 'lldb'
  end
  if value ~= 'lldb' and value ~= 'gdb' then
    vim.notify('Choose gdb, lldb, or toggle', vim.log.levels.WARN)
    return false
  end
  local dap = require 'dap'
  if next(dap.sessions()) then
    vim.notify('Terminate or disconnect the active debug session before switching', vim.log.levels.WARN)
    return false
  end
  local adapter = value == 'gdb' and 'gdb' or 'codelldb'
  if not dap.adapters[adapter] then
    vim.notify('Debugger adapter unavailable: ' .. adapter, vim.log.levels.ERROR)
    return false
  end
  backend = value
  for _, refresh in ipairs(profiles) do
    refresh()
  end
  vim.notify('Native debugger: ' .. backend:upper() .. (backend == 'lldb' and ' (CodeLLDB)' or ' (DAP; interactive stdin requires LLDB)'))
  return true
end

function M.root(path)
  path = path or vim.api.nvim_buf_get_name(0)
  return vim.fs.root(path ~= '' and path or vim.fn.getcwd(), { 'CMakeLists.txt', 'Makefile', 'Cargo.toml', 'build.zig', 'compile_commands.json', '.git' })
    or vim.fn.getcwd()
end

function M.program(default_dir)
  local ok, path = pcall(vim.fn.input, 'Executable: ', M.root() .. '/' .. (default_dir or ''), 'file')
  if not ok or path == '' then
    return require('dap').ABORT
  end
  path = vim.fn.fnamemodify(vim.fn.expand(path), ':p')
  if vim.fn.isdirectory(path) == 1 or vim.fn.executable(path) ~= 1 then
    vim.notify('Not an executable file: ' .. path, vim.log.levels.ERROR)
    return require('dap').ABORT
  end
  return path
end

---@return string[]?
---@return string? error
function M.parse_args(input)
  if input == '' then
    return {}
  end
  local ok, args = pcall(vim.json.decode, input)
  if not ok or type(args) ~= 'table' or not vim.islist(args) or not input:match '^%s*%[' then
    return nil, 'Arguments must be a JSON array, for example ["--name", "Ada Lovelace"]'
  end
  for _, arg in ipairs(args) do
    if type(arg) ~= 'string' or arg:find('\0', 1, true) then
      return nil, 'Every argument must be a string without NUL characters'
    end
  end
  return args
end

function M.args()
  local ok, input = pcall(vim.fn.input, 'Arguments as JSON array: ', '[]')
  if not ok then
    return require('dap').ABORT
  end
  local args, err = M.parse_args(input)
  if not args then
    vim.notify(err, vim.log.levels.ERROR)
    return require('dap').ABORT
  end
  return args
end

function M.configurations(default_dir, language)
  local configs = {}
  local adapters = { M.adapter() }
  if require('dap').adapters['lldb-dap'] then
    adapters[#adapters + 1] = 'lldb-dap'
  end
  for _, adapter in ipairs(adapters) do
    local launch = vim.tbl_extend('force', M.launch_options(adapter, language), {
      name = 'Launch binary (' .. adapter .. ')',
      type = adapter,
      request = 'launch',
      program = function()
        return M.program(default_dir)
      end,
      args = M.args,
      cwd = M.root,
    })
    configs[#configs + 1] = launch
    configs[#configs + 1] = {
      name = 'Attach to process (' .. adapter .. ')',
      type = adapter,
      request = 'attach',
      pid = require('dap.utils').pick_process,
      cwd = M.root,
      initCommands = launch.initCommands,
    }
  end
  profiles[#profiles + 1] = function()
    local adapter = M.adapter()
    local launch = configs[1]
    for _, key in ipairs { 'terminal', 'sourceLanguages', 'runInTerminal', 'initCommands' } do
      launch[key] = nil
    end
    for key, value in pairs(M.launch_options(adapter, language)) do
      launch[key] = value
    end
    launch.name = 'Launch binary (' .. adapter .. ')'
    configs[2].type = adapter
    configs[2].name = 'Attach to process (' .. adapter .. ')'
    configs[2].initCommands = launch.initCommands
  end
  return configs
end

function M.setup()
  local gdb = vim.fn.exepath 'gdb'
  if gdb ~= '' then
    require('dap').adapters.gdb = {
      type = 'executable',
      command = gdb,
      args = { '--quiet', '--interpreter=dap', '-iex', 'set pagination off' },
    }
  end
  for _, name in ipairs { 'lldb-dap', 'lldb-dap-21' } do
    local path = vim.fn.exepath(name)
    if path ~= '' then
      require('dap').adapters['lldb-dap'] = { type = 'executable', command = path, name = 'lldb-dap' }
      break
    end
  end
  vim.api.nvim_create_user_command('DebugBackend', function(opts)
    if opts.args == '' then
      vim.notify('Native debugger: ' .. backend:upper())
    else
      M.set_backend(opts.args)
    end
  end, {
    nargs = '?',
    desc = 'Select the native debugger for subsequent launches',
    complete = function()
      return { 'gdb', 'lldb', 'toggle' }
    end,
  })
end

return M
