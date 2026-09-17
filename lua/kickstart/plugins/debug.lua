-- debug.lua
--
-- DAP (Debug Adapter Protocol) configuration.
-- Uses mason-nvim-dap for automatic debugger installation.

return {
  'mfussenegger/nvim-dap',
  cmd = { 'DebugBackend' },
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
    {
      '<leader>dg',
      function()
        require('custom.debug_native').set_backend 'toggle'
      end,
      desc = 'Toggle GDB / LLDB',
    },
    -- Function key shortcuts (muscle memory / VSCode-style)
    {
      '<F5>',
      function()
        require('dap').continue()
      end,
      desc = 'Debug: Continue',
    },
    {
      '<F10>',
      function()
        require('dap').step_over()
      end,
      desc = 'Debug: Step Over',
    },
    {
      '<F11>',
      function()
        require('dap').step_into()
      end,
      desc = 'Debug: Step Into',
    },
    {
      '<S-F11>',
      function()
        require('dap').step_out()
      end,
      desc = 'Debug: Step Out',
    },
    -- <leader>d prefix
    {
      '<leader>dc',
      function()
        require('dap').continue()
      end,
      desc = 'Continue',
    },
    {
      '<leader>di',
      function()
        require('dap').step_into()
      end,
      desc = 'Step Into',
    },
    {
      '<leader>do',
      function()
        require('dap').step_over()
      end,
      desc = 'Step Over',
    },
    {
      '<leader>du',
      function()
        require('dap').step_out()
      end,
      desc = 'Step O[u]t',
    },
    {
      '<leader>db',
      function()
        require('dap').toggle_breakpoint()
      end,
      desc = 'Toggle Breakpoint',
    },
    {
      '<leader>dB',
      function()
        require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end,
      desc = 'Conditional Breakpoint',
    },
    {
      '<leader>dl',
      function()
        require('dap').set_breakpoint(nil, nil, vim.fn.input 'Log point message: ')
      end,
      desc = 'Log Point',
    },
    {
      '<leader>dL',
      function()
        require('dap').list_breakpoints()
      end,
      desc = '[L]ist breakpoints (quickfix)',
    },
    {
      '<leader>dx',
      function()
        require('dap').set_exception_breakpoints()
      end,
      desc = 'Choose e[x]ception filters',
    },
    {
      '<leader>dr',
      function()
        require('dap').repl.open()
      end,
      desc = 'Open REPL',
    },
    {
      '<leader>ds',
      function()
        require('dap').run_last()
      end,
      desc = 'Run La[s]t',
    },
    {
      '<leader>dt',
      function()
        require('dap').terminate()
      end,
      desc = 'Terminate',
    },
    {
      '<leader>dd',
      function()
        require('dap').disconnect()
      end,
      desc = 'Disconnect',
    },
    {
      '<leader>dw',
      function()
        require('dapui').toggle()
      end,
      desc = 'Toggle UI [w]indow',
    },
    {
      '<leader>dW',
      function()
        require('custom.debug_workspace').open()
      end,
      desc = 'Open debug [W]orkspace tab',
    },
    {
      '<leader>dR',
      function()
        require('dap').run_to_cursor()
      end,
      desc = '[R]un to cursor',
    },
    {
      '<leader>de',
      function()
        require('dapui').eval()
      end,
      desc = 'Eval under cursor',
      mode = { 'n', 'v' },
    },
    {
      '<leader>df',
      function()
        require('dapui').float_element()
      end,
      desc = 'Float element',
    },
    {
      '<leader>dp',
      function()
        require('dap').pause()
      end,
      desc = 'Pause',
    },
    {
      '<leader>dv',
      function()
        require('nvim-dap-virtual-text').toggle()
      end,
      desc = 'Toggle [v]irtual text',
    },
    {
      '<leader>da',
      function()
        require('custom.debug_pick').pick()
      end,
      desc = 'Pick target & debug ([a]uto-build)',
    },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    -- Virtual text (inline variable values) — off by default; <leader>dv toggles
    require('nvim-dap-virtual-text').setup { enabled = false }

    -- Breakpoint gutter signs. The guide hardcodes a 🐞; tying text to highlight
    -- groups instead keeps the colors in sync with the active colorscheme.
    -- DapStopped also highlights the whole current line (linehl) so the paused
    -- frame is obvious.
    for name, sign in pairs {
      DapBreakpoint = { text = '●', hl = 'DiagnosticError' },
      DapBreakpointCondition = { text = '◆', hl = 'DiagnosticWarn' },
      DapLogPoint = { text = '◆', hl = 'DiagnosticInfo' },
      DapBreakpointRejected = { text = '✗', hl = 'DiagnosticError' },
      DapStopped = { text = '▶', hl = 'DiagnosticOk', linehl = 'Visual' },
    } do
      vim.fn.sign_define(name, {
        text = sign.text,
        texthl = sign.hl,
        numhl = sign.hl,
        linehl = sign.linehl,
      })
    end

    -- Mason-DAP: auto-install debuggers
    require('mason-nvim-dap').setup {
      automatic_installation = true,
      handlers = {},
      ensure_installed = {
        'delve', -- Go
        'python', -- Python (debugpy)
        'js', -- JavaScript/TypeScript (js-debug → pwa-node; replaces archived node2)
        'codelldb', -- Rust / C / C++ (lldb-based; replaces cppdbg)
        'bash', -- Bash
      },
    }

    -- DAP UI
    dapui.setup {
      layouts = {
        {
          position = 'right',
          size = 45,
          elements = {
            { id = 'scopes', size = 0.4 },
            { id = 'watches', size = 0.2 },
            { id = 'stacks', size = 0.25 },
            { id = 'breakpoints', size = 0.15 },
          },
        },
        { position = 'bottom', size = 0.25, elements = { { id = 'repl', size = 0.5 }, { id = 'console', size = 0.5 } } },
      },
      floating = { border = 'rounded', max_width = 100, max_height = 30 },
      render = { max_value_lines = 5 },
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

    -- Keep final output available until the user closes the UI.
    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = nil
    dap.listeners.before.event_exited['dapui_config'] = nil

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

    local native = require 'custom.debug_native'
    native.setup()
    dap.configurations.c = native.configurations()
    dap.configurations.cpp = dap.configurations.c
    dap.configurations.rust = native.configurations('target/debug/', 'rust')
    dap.configurations.zig = native.configurations 'zig-out/bin/'

    -- JavaScript / TypeScript (js-debug / pwa-node).
    -- node2 is Microsoft-archived; js-debug is the adapter VS Code ships, on the
    -- Chrome DevTools Protocol — child-process/worker auto-attach, reliable TS
    -- source maps, current Node support. This mason-nvim-dap version ships no
    -- `js` adapter mapping, so register pwa-node by hand: the mason
    -- `js-debug-adapter` shim starts the DAP server on the port we pass it.
    dap.adapters['pwa-node'] = {
      type = 'server',
      host = 'localhost',
      port = '${port}',
      executable = {
        command = vim.fn.exepath 'js-debug-adapter',
        args = { '${port}' },
      },
    }

    local node_launch = {
      type = 'pwa-node',
      request = 'launch',
      name = 'Launch file',
      program = '${file}',
      cwd = '${workspaceFolder}',
      sourceMaps = true,
      skipFiles = { '<node_internals>/**' },
      console = 'integratedTerminal',
    }
    local node_attach = {
      type = 'pwa-node',
      request = 'attach',
      name = 'Attach to process',
      processId = require('dap.utils').pick_process,
      cwd = '${workspaceFolder}',
      sourceMaps = true,
      skipFiles = { '<node_internals>/**' },
    }
    -- TS launches through tsx (matches <leader>cr); source maps land breakpoints
    -- on the right .ts line. Listed first so it's the default pick for TS files.
    local tsx_launch = {
      type = 'pwa-node',
      request = 'launch',
      name = 'Launch file (tsx)',
      runtimeExecutable = 'npx',
      runtimeArgs = { 'tsx', '${file}' },
      cwd = '${workspaceFolder}',
      sourceMaps = true,
      skipFiles = { '<node_internals>/**' },
      console = 'integratedTerminal',
    }

    dap.configurations.javascript = { node_launch, node_attach }
    dap.configurations.javascriptreact = { node_launch, node_attach }
    dap.configurations.typescript = { tsx_launch, node_launch, node_attach }
    dap.configurations.typescriptreact = { tsx_launch, node_launch, node_attach }

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
