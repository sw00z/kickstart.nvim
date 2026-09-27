return {
  { -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          local bufnr = vim.api.nvim_get_current_buf()
          -- Linters otherwise run only on save; lint even when formatting fails, e.g. on a syntax error.
          require('conform').format({ async = true, lsp_format = 'fallback' }, function()
            if vim.api.nvim_buf_is_valid(bufnr) then
              vim.api.nvim_buf_call(bufnr, function()
                vim.cmd.Lint()
              end)
            end
          end)
        end,
        mode = '',
        desc = '[F]ormat and lint buffer',
      },
    },
    opts = {
      -- Surface formatter failures (binary missing, timeout, parse error).
      -- Without this, your file silently stays unformatted and you can't tell
      -- why — the formatter is the canonical indent source, so failures matter.
      notify_on_error = true,
      format_on_save = function(bufnr)
        require('custom.lsp_tools').eslint_fix(bufnr)
        return {
          -- 1500ms covers cold-start formatters (zig fmt, prettierd boot,
          -- swiftformat first run). 500ms was too tight on first invocation.
          timeout_ms = 1500,
          lsp_format = 'fallback',
        }
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        -- Conform can also run multiple formatters sequentially
        python = { 'ruff_organize_imports', 'ruff_format' },
        --
        c = { 'clang-format' },
        cpp = { 'clang-format' },
        -- gofumpt (superset of gofmt) matches gopls' `gofumpt = true`, so
        -- conform-on-save and LSP fallback formatting produce identical output.
        go = { 'goimports', 'gofumpt' },
        rust = { 'rustfmt', lsp_format = 'fallback' },
        zig = { 'zigfmt' },
        odin = { 'odinfmt' },
        toml = { 'taplo' },
        terraform = { 'terraform_fmt' },
        hcl = { 'terraform_fmt' },
        ['_'] = { 'trim_whitespace' },
        -- You can use 'stop_after_first' to run the first available formatter from the list
        -- prettierd is faster than prettier (runs as daemon)
        javascript = { 'prettierd', 'prettier', stop_after_first = true },
        typescript = { 'prettierd', 'prettier', stop_after_first = true },
        javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        json = { 'prettierd', 'prettier', stop_after_first = true },
        html = { 'prettierd', 'prettier', stop_after_first = true },
        css = { 'prettierd', 'prettier', stop_after_first = true },
        markdown = { 'prettierd', 'prettier', stop_after_first = true },
        yaml = { 'prettierd', 'prettier', stop_after_first = true },
        -- New languages
        sql = { 'sqlfluff', 'sql_formatter', stop_after_first = true },
        kotlin = { 'ktlint' },
        swift = { 'swiftformat' }, -- swiftformat: brew install swiftformat (or apt)
      },
      formatters = {
        prettier = {
          prepend_args = function(self, ctx)
            return require('custom.lsp_tools').prettier_args(self, ctx)
          end,
        },
        prettierd = {
          env = function()
            return require('custom.lsp_tools').prettierd_env()
          end,
        },
      },
    },
  },
}

-- vim: ts=2 sts=2 sw=2 et
