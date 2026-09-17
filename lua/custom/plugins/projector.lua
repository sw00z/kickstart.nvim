return {
  'kndndrj/nvim-projector',
  dependencies = {
    -- required:
    'MunifTanjim/nui.nvim',
    -- optional extensions:
    'kndndrj/projector-neotest',
    'kndndrj/projector-dbee',
    -- dependencies of extensions:
    'nvim-neotest/neotest',
    'kndndrj/nvim-dbee',
  },
  keys = {
    {
      '<leader>jc',
      function()
        require('projector').continue()
      end,
      desc = 'Continue',
    },
    {
      '<leader>jo',
      function()
        require('projector').continue()
      end,
      desc = 'Open Dashboard',
    },
    {
      '<leader>jt',
      function()
        require('projector').toggle()
      end,
      desc = 'Toggle UI',
    },
    {
      '<leader>jn',
      function()
        require('projector').next()
      end,
      desc = 'Next config',
    },
    {
      '<leader>jp',
      function()
        require('projector').previous()
      end,
      desc = 'Previous config',
    },
    {
      '<leader>jr',
      function()
        require('projector').restart()
      end,
      desc = 'Restart',
    },
    {
      '<leader>jk',
      function()
        require('projector').kill()
      end,
      desc = 'Kill',
    },
  },
  config = function()
    local loaders = require 'projector.loaders'
    local outputs = require 'projector.outputs'

    -- Track the last-focused real C/C++ buffer. projector expands config
    -- fields against the CURRENT buffer at task-run time, and a build task
    -- runs while a dap-ui window ("DAP Scopes", etc.) may be focused — so
    -- ${file}/${fileBasenameNoExtension} would resolve to a UI buffer name.
    -- The single-file configs below read this pinned path instead.
    vim.api.nvim_create_autocmd('BufEnter', {
      pattern = { '*.c', '*.cpp', '*.cc', '*.cxx', '*.cppm', '*.h', '*.hpp', '*.hh', '*.zig' },
      callback = function(a)
        local name = vim.api.nvim_buf_get_name(a.buf)
        if name ~= '' then
          vim.g.projector_source_file = name
        end
      end,
    })

    -- Absolute path to the C/C++ source to build: pinned buffer if still
    -- readable, else the current buffer (covers the first run before any
    -- BufEnter fired).
    local function source_file()
      local f = vim.g.projector_source_file
      if f and f ~= '' and vim.fn.filereadable(f) == 1 then
        return f
      end
      return vim.fn.expand '%:p'
    end

    -- Absolute path to the build output (source path minus extension).
    local function source_binary()
      return vim.fn.fnamemodify(source_file(), ':r')
    end

    -- Scan conventional build-output dirs for executables at launch time.
    -- One match: use it. Several: numbered pick. None: path prompt.
    -- Blocking inputlist on purpose: projector expands config fields
    -- synchronously, so async pickers can't be used here (<leader>da can).
    local function pick_built_binary()
      local candidates = require('custom.debug_pick').scan_executables()
      if #candidates == 0 then
        return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
      end
      if #candidates == 1 then
        return candidates[1]
      end
      local choices = { 'Select executable:' }
      for i, c in ipairs(candidates) do
        table.insert(choices, i .. ': ' .. vim.fn.fnamemodify(c, ':.'))
      end
      local idx = vim.fn.inputlist(choices)
      if idx < 1 or idx > #candidates then
        return ''
      end
      return candidates[idx]
    end

    require('projector').setup {
      loaders = {
        -- Per-project tasks/configs: <project>/.vim/projector.json
        -- (JSON list of configs; whole-line // comments allowed).
        -- `configs` adds global entries available in every directory.
        loaders.BuiltinLoader:new {
          path = function()
            return vim.fn.getcwd() .. '/.vim/projector.json'
          end,
          configs = {
            -- Single-file C/C++ build-and-debug, no project files needed.
            -- command/args/program are functions evaluated at run time and
            -- read source_file()/source_binary() (the pinned C/C++ buffer),
            -- so a focused dap-ui window can't poison the path. Absolute
            -- compiler paths dodge the PATH-shadowed Zig LLVM; -g (not
            -- -glldb) keeps DWARF readable by both lldb and gdb.
            -- `dependencies` = task ids to run first (vscode preLaunchTask);
            -- `after` = postDebugTask equivalent.
            {
              id = 'compile-cpp-file',
              name = 'Compile current C++ file (clang)',
              command = '/usr/bin/clang++-21',
              args = function()
                return { '-std=c++23', '-g', '-fstandalone-debug', source_file(), '-o', source_binary() }
              end,
              cwd = '${workspaceFolder}',
            },
            {
              id = 'compile-c-file',
              name = 'Compile current C file (clang)',
              command = '/usr/bin/clang-21',
              args = function()
                return { '-std=c23', '-g', '-fstandalone-debug', source_file(), '-o', source_binary() }
              end,
              cwd = '${workspaceFolder}',
            },
            -- gcc variants (-fstandalone-debug is clang-only)
            {
              id = 'compile-cpp-file-gcc',
              name = 'Compile current C++ file (g++)',
              command = '/usr/bin/g++-15',
              args = function()
                return { '-std=c++23', '-g', source_file(), '-o', source_binary() }
              end,
              cwd = '${workspaceFolder}',
            },
            {
              id = 'compile-c-file-gcc',
              name = 'Compile current C file (gcc)',
              command = '/usr/bin/gcc-15',
              args = function()
                return { '-std=c23', '-g', source_file(), '-o', source_binary() }
              end,
              cwd = '${workspaceFolder}',
            },
            {
              id = 'debug-cpp-file',
              name = 'Build & debug current C++ file (clang)',
              type = 'codelldb',
              request = 'launch',
              program = source_binary,
              cwd = '${workspaceFolder}',
              stopOnEntry = false,
              dependencies = { 'compile-cpp-file' },
            },
            {
              id = 'debug-c-file',
              name = 'Build & debug current C file (clang)',
              type = 'codelldb',
              request = 'launch',
              program = source_binary,
              cwd = '${workspaceFolder}',
              stopOnEntry = false,
              dependencies = { 'compile-c-file' },
            },
            {
              id = 'debug-cpp-file-gcc',
              name = 'Build & debug current C++ file (g++)',
              type = 'codelldb',
              request = 'launch',
              program = source_binary,
              cwd = '${workspaceFolder}',
              stopOnEntry = false,
              dependencies = { 'compile-cpp-file-gcc' },
            },
            {
              id = 'debug-c-file-gcc',
              name = 'Build & debug current C file (gcc)',
              type = 'codelldb',
              request = 'launch',
              program = source_binary,
              cwd = '${workspaceFolder}',
              stopOnEntry = false,
              dependencies = { 'compile-c-file-gcc' },
            },
            -- Zig single file: build-exe in Debug mode emits native DWARF
            -- that codelldb reads; source_binary() drops the .zig extension.
            {
              id = 'compile-zig-file',
              name = 'Compile current Zig file',
              command = '/home/swooz/local/zig-release/bin/zig',
              args = function()
                return { 'build-exe', '-O', 'Debug', '-femit-bin=' .. source_binary(), source_file() }
              end,
              cwd = '${workspaceFolder}',
            },
            {
              id = 'debug-zig-file',
              name = 'Build & debug current Zig file',
              type = 'codelldb',
              request = 'launch',
              program = source_binary,
              cwd = '${workspaceFolder}',
              stopOnEntry = false,
              dependencies = { 'compile-zig-file' },
            },
            -- Project binaries: auto-detects in build/, bin/, out/,
            -- zig-out/bin/. Build step stays per-project (the build
            -- command isn't guessable) — see .vim/projector.json template.
            {
              id = 'debug-built-binary',
              name = 'Debug built binary (auto-detect)',
              type = 'codelldb',
              request = 'launch',
              program = pick_built_binary,
              cwd = '${workspaceFolder}',
              stopOnEntry = false,
            },
          },
        },
        -- DapLoader deliberately omitted: it flattens every entry of
        -- dap.configurations across all filetypes, and projector indexes
        -- tasks by name — duplicate names ('Launch binary' for c/cpp/rust,
        -- mason defaults) silently collapse, last writer wins. The dap
        -- fallbacks stay on the <F5> picker where filetype scoping applies.
      },
      outputs = {
        -- Task and Dap builders are required for shell tasks and debug
        -- sessions; passing `outputs` replaces the defaults entirely, so
        -- they must be listed alongside the extension builders.
        outputs.TaskOutputBuilder:new(),
        outputs.DapOutputBuilder:new(),
        require('projector_dbee').OutputBuilder:new(),
        require('projector_neotest').OutputBuilder:new { group = true, include_debug = true },
      },
    }
  end,
}
