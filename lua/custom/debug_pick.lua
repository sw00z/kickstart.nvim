-- debug_pick.lua
--
-- <leader>da launcher: fuzzy-pick a debug target via vim.ui.select
-- (telescope-ui-select), building first when needed, then launch it
-- under codelldb via dap.run(). Lives outside custom/plugins/ because
-- it is a helper module, not a lazy.nvim spec.
--
-- Compilers use absolute paths: bare clang*-21 names depend on PATH
-- shadowing the compiler-rt-less Zig LLVM build. -g (not -glldb) keeps
-- the DWARF readable by both lldb/codelldb and gdb.

local M = {}

-- Zig install (the version-pinned release build, not a PATH lookup).
local ZIG = '/home/swooz/local/zig-release/bin/zig'

-- argv prefixes per compiler and language; file/-o appended at call time.
-- Zig is handled separately (build-exe has a different argument shape).
local COMPILERS = {
  clang = {
    cpp = { '/usr/bin/clang++-21', '-std=c++23', '-g', '-fstandalone-debug' },
    c = { '/usr/bin/clang-21', '-std=c23', '-g', '-fstandalone-debug' },
  },
  gcc = {
    cpp = { '/usr/bin/g++-15', '-std=c++23', '-g' },
    c = { '/usr/bin/gcc-15', '-std=c23', '-g' },
  },
}

---Build argv for one source file. Zig: `build-exe -O Debug -femit-bin`.
---@param kind 'clang'|'gcc'|'zig'
---@param ft string buffer filetype
---@param file string absolute source path
---@param bin string absolute output path (file minus extension)
---@return string[]
local function build_cmd_for(kind, ft, file, bin)
  if kind == 'zig' then
    return { ZIG, 'build-exe', '-O', 'Debug', '-femit-bin=' .. bin, file }
  end
  local lang = ft == 'c' and 'c' or 'cpp'
  return vim.list_extend(vim.deepcopy(COMPILERS[kind][lang]), { file, '-o', bin })
end

---@param path string
---@return boolean
local function is_elf(path)
  local f = io.open(path, 'rb')
  if not f then
    return false
  end
  local magic = f:read(4)
  f:close()
  return magic == '\127ELF'
end

---Also used by the projector dashboard's 'Debug built binary' entry.
---@return string[] absolute paths of executables in conventional output dirs
function M.scan_executables(root)
  local cwd = root or vim.fn.getcwd()
  local found, seen = {}, {}
  for _, dir in ipairs { 'build', 'build/bin', 'build/debug', 'build/Debug', 'bin', 'out', 'zig-out/bin', 'target/debug', '.' } do
    local abs = dir == '.' and cwd or (cwd .. '/' .. dir)
    -- isdirectory guard instead of pcall: readdir on a missing dir echoes
    -- E484 into :messages even when the Lua error is caught
    if vim.fn.isdirectory(abs) == 1 then
      for _, name in ipairs(vim.fn.readdir(abs)) do
        local path = abs .. '/' .. name
        if not seen[path] and vim.fn.isdirectory(path) == 0 and vim.fn.executable(path) == 1 and is_elf(path) then
          seen[path] = true
          table.insert(found, path)
        end
      end
    end
  end
  return found
end

---@return string[]? build command for the detected build system
---@return string? label for notifications
local function detect_build(cwd)
  if vim.fn.filereadable(cwd .. '/CMakeLists.txt') == 1 then
    for _, dir in ipairs { 'build/debug', 'build/Debug', 'build' } do
      if vim.fn.filereadable(cwd .. '/' .. dir .. '/CMakeCache.txt') == 1 then
        return { 'cmake', '--build', dir, '--config', 'Debug' }, 'cmake ' .. dir
      end
    end
    -- Use the project's selected compiler and generator.
    return {
      'cmake',
      '-S',
      cwd,
      '-B',
      cwd .. '/build/debug',
      '-DCMAKE_BUILD_TYPE=Debug',
      '-DCMAKE_EXPORT_COMPILE_COMMANDS=ON',
    },
      'cmake configure'
  end
  if vim.fn.filereadable(cwd .. '/Makefile') == 1 then
    return { 'make' }, 'make'
  end
  if vim.fn.filereadable(cwd .. '/build.zig') == 1 then
    return { ZIG, 'build' }, 'zig build'
  end
  return nil
end

---@param program string absolute path to the binary
local function launch(program, root)
  if vim.fn.executable(program) ~= 1 or not is_elf(program) then
    vim.notify('Select a native ELF executable: ' .. program, vim.log.levels.ERROR)
    return
  end
  local args = require('custom.debug_native').args()
  if args == require('dap').ABORT then
    return
  end
  local native = require 'custom.debug_native'
  require('dap').run(vim.tbl_extend('force', native.launch_options(native.adapter()), {
    name = 'Launch ' .. vim.fn.fnamemodify(program, ':t') .. ' (' .. native.adapter() .. ')',
    request = 'launch',
    program = program,
    cwd = root,
    args = args,
  }))
end

---@param cmd string[]
---@param label string
---@param on_success fun()
local function run_build(cmd, label, root, on_success)
  vim.notify('Building (' .. label .. ')…', vim.log.levels.INFO)
  vim.system(cmd, { cwd = root, text = true }, function(out)
    vim.schedule(function()
      if out.code == 0 then
        on_success()
      else
        vim.notify('Build failed (' .. label .. '):\n' .. (out.stderr or ''), vim.log.levels.ERROR)
      end
    end)
  end)
end

---@param kind 'clang'|'gcc'|'zig'
---@param ft string filetype snapshotted at pick() time
---@param file string absolute source path snapshotted at pick() time
local function compile_current_then_launch(kind, ft, file, root, buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local ok, err = pcall(vim.api.nvim_buf_call, buf, function()
    vim.cmd.update()
  end)
  if not ok then
    vim.notify(tostring(err), vim.log.levels.ERROR)
    return
  end
  local bin = vim.fn.fnamemodify(file, ':r')
  run_build(build_cmd_for(kind, ft, file, bin), kind .. ' single file', root, function()
    launch(bin, root)
  end)
end

---@param exes string[]
local function pick_and_launch(exes, root)
  if #exes == 0 then
    local path = vim.fn.input('Path to executable: ', root .. '/', 'file')
    if path ~= '' then
      launch(path, root)
    end
    return
  end
  if #exes == 1 then
    launch(exes[1], root)
    return
  end
  vim.ui.select(exes, {
    prompt = 'Debug binary',
    format_item = function(p)
      return vim.fn.fnamemodify(p, ':.')
    end,
  }, function(choice)
    if choice then
      launch(choice, root)
    end
  end)
end

function M.pick()
  -- Snapshot the source NOW, while it's focused. vim.ui.select opens and
  -- closes a picker window before the chosen action runs, so reading the
  -- file inside the callback could pick up the wrong buffer.
  local src = vim.fn.expand '%:p'
  local ft = vim.bo.filetype
  local buf = vim.api.nvim_get_current_buf()
  local root = require('custom.debug_native').root(src)

  ---@type { label: string, run: fun() }[]
  local items = {}

  for _, exe in ipairs(M.scan_executables(root)) do
    table.insert(items, {
      label = vim.fn.fnamemodify(exe, ':.'),
      run = function()
        launch(exe, root)
      end,
    })
  end

  local build_cmd, build_label = detect_build(root)
  if build_cmd then
    table.insert(items, {
      label = '[build project (' .. build_label .. '), then pick binary]',
      run = function()
        run_build(build_cmd, build_label, root, function()
          if build_label == 'cmake configure' then
            run_build({ 'cmake', '--build', 'build/debug', '--config', 'Debug' }, 'cmake', root, function()
              pick_and_launch(M.scan_executables(root), root)
            end)
          else
            pick_and_launch(M.scan_executables(root), root)
          end
        end)
      end,
    })
  end

  if ft == 'c' or ft == 'cpp' then
    local gcc_label = ft == 'c' and 'gcc' or 'g++'
    table.insert(items, {
      label = '[compile current file & debug (clang)]',
      run = function()
        compile_current_then_launch('clang', ft, src, root, buf)
      end,
    })
    table.insert(items, {
      label = '[compile current file & debug (' .. gcc_label .. ')]',
      run = function()
        compile_current_then_launch('gcc', ft, src, root, buf)
      end,
    })
  elseif ft == 'zig' then
    table.insert(items, {
      label = '[compile current file & debug (zig)]',
      run = function()
        compile_current_then_launch('zig', ft, src, root, buf)
      end,
    })
  end

  if #items == 0 then
    pick_and_launch({}, root)
    return
  end

  vim.ui.select(items, {
    prompt = 'Debug target',
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if choice then
      choice.run()
    end
  end)
end

return M
