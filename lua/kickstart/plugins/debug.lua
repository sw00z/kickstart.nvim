-- debug.lua
--
-- DAP (Debug Adapter Protocol) configuration.
-- Uses mason-nvim-dap for automatic debugger installation.

return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',
    'theHamsta/nvim-dap-virtual-text',
    -- Language-specific helpers
    'leoluz/nvim-dap-go',
  },
  keys = {
    -- Function key shortcuts (muscle memory / VSCode-style)
    { '<F5>', function() require('dap').continue() end, desc = 'Debug: Continue' },
    { '<F10>', function() require('dap').step_over() end, desc = 'Debug: Step Over' },
    { '<F11>', function() require('dap').step_into() end, desc = 'Debug: Step Into' },
    { '<S-F11>', function() require('dap').step_out() end, desc = 'Debug: Step Out' },
    -- <leader>d prefix
    { '<leader>dc', function() require('dap').continue() end, desc = 'Continue' },
    { '<leader>di', function() require('dap').step_into() end, desc = 'Step Into' },
    { '<leader>do', function() require('dap').step_over() end, desc = 'Step Over' },
    { '<leader>du', function() require('dap').step_out() end, desc = 'Step O[u]t' },
    { '<leader>db', function() require('dap').toggle_breakpoint() end, desc = 'Toggle Breakpoint' },
    { '<leader>dB', function() require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, desc = 'Conditional Breakpoint' },
    { '<leader>dl', function() require('dap').set_breakpoint(nil, nil, vim.fn.input 'Log point message: ') end, desc = 'Log Point' },
    { '<leader>dr', function() require('dap').repl.open() end, desc = 'Open REPL' },
    { '<leader>ds', function() require('dap').run_last() end, desc = 'Run La[s]t' },
    { '<leader>dt', function() require('dap').terminate() end, desc = 'Terminate' },
    { '<leader>dd', function() require('dap').disconnect() end, desc = 'Disconnect' },
    { '<leader>dw', function() require('dapui').toggle() end, desc = 'Toggle UI [w]indow' },
    { '<leader>de', function() require('dapui').eval() end, desc = 'Eval under cursor', mode = { 'n', 'v' } },
    { '<leader>df', function() require('dapui').float_element() end, desc = 'Float element' },
    { '<leader>dp', function() require('dap').pause() end, desc = 'Pause' },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    -- Virtual text (inline variable values)
    require('nvim-dap-virtual-text').setup {}

    -- Mason-DAP: auto-install debuggers
    require('mason-nvim-dap').setup {
      automatic_installation = true,
      handlers = {},
      ensure_installed = {
        'delve', -- Go
        'python', -- Python (debugpy)
        'node2', -- JavaScript/TypeScript
        'cppdbg', -- C/C++
        'codelldb', -- Rust / C / C++ (lldb)
        'bash', -- Bash
      },
    }

    -- DAP UI
    dapui.setup {
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    -- Auto open/close UI on debug session
    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    -- =====================
    -- Language Configurations
    -- =====================

    -- Go (via nvim-dap-go — handles adapter + configs)
    require('dap-go').setup {
      delve = {
        detached = vim.fn.has 'win32' == 0,
      },
    }

    -- Python (debugpy — venv-aware)
    dap.configurations.python = {
      {
        type = 'python',
        request = 'launch',
        name = 'Launch file',
        program = '${file}',
        pythonPath = function()
          local cwd = vim.fn.getcwd()
          local venv = os.getenv 'VIRTUAL_ENV' or os.getenv 'CONDA_PREFIX'
          if venv then
            return venv .. '/bin/python'
          elseif vim.fn.executable(cwd .. '/.venv/bin/python') == 1 then
            return cwd .. '/.venv/bin/python'
          elseif vim.fn.executable(cwd .. '/venv/bin/python') == 1 then
            return cwd .. '/venv/bin/python'
          else
            return 'python3'
          end
        end,
      },
      {
        type = 'python',
        request = 'launch',
        name = 'Launch file with args',
        program = '${file}',
        args = function()
          return vim.split(vim.fn.input 'Arguments: ', ' ')
        end,
        pythonPath = function()
          local venv = os.getenv 'VIRTUAL_ENV' or os.getenv 'CONDA_PREFIX'
          if venv then
            return venv .. '/bin/python'
          end
          return 'python3'
        end,
      },
    }

    -- C/C++ (cppdbg)
    dap.configurations.c = {
      {
        name = 'Launch file',
        type = 'cppdbg',
        request = 'launch',
        program = function()
          return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        cwd = '${workspaceFolder}',
        stopAtEntry = false,
      },
    }
    dap.configurations.cpp = dap.configurations.c

    -- Rust (codelldb)
    dap.configurations.rust = {
      {
        name = 'Launch file',
        type = 'codelldb',
        request = 'launch',
        program = function()
          return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/target/debug/', 'file')
        end,
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
      },
    }

    -- JavaScript / TypeScript (node2)
    dap.configurations.javascript = {
      {
        name = 'Launch file',
        type = 'node2',
        request = 'launch',
        program = '${file}',
        cwd = '${workspaceFolder}',
        sourceMaps = true,
        protocol = 'inspector',
        console = 'integratedTerminal',
      },
      {
        name = 'Attach to process',
        type = 'node2',
        request = 'attach',
        processId = require('dap.utils').pick_process,
      },
    }
    dap.configurations.typescript = dap.configurations.javascript

    -- Bash (bashdb)
    dap.configurations.sh = {
      {
        name = 'Launch file',
        type = 'bash',
        request = 'launch',
        program = '${file}',
        cwd = '${workspaceFolder}',
      },
    }
  end,
}
