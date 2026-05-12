return {
  { -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        -- Disable "format_on_save lsp_fallback" for languages that don't
        -- have a well standardized coding style. You can add additional
        -- languages here or re-enable it for the disabled ones.
        local disable_filetypes = { c = true, cpp = true }
        local lsp_format_opt
        if disable_filetypes[vim.bo[bufnr].filetype] then
          lsp_format_opt = 'never'
        else
          lsp_format_opt = 'fallback'
        end
        return {
          timeout_ms = 500,
          lsp_format = lsp_format_opt,
        }
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        -- Conform can also run multiple formatters sequentially
        python = { 'ruff_organize_imports', 'ruff_format' },
        --
        c = { 'clang-format' },
        cpp = { 'clang-format' },
        go = { 'goimports', 'gofmt' },
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
        prettierd = {
          -- Only use fallback config if no project config exists
          prepend_args = function(self, ctx)
            -- Check if project has a prettier config
            local has_config = vim.fs.find({
              '.prettierrc',
              '.prettierrc.json',
              '.prettierrc.yml',
              '.prettierrc.yaml',
              '.prettierrc.js',
              'prettier.config.js',
              '.prettierrc.toml',
            }, { upward = true, path = ctx.dirname })[1]

            if has_config then
              return {}
            end
            -- Fallback to your global config
            return { '--config', vim.fn.expand '~/.config/prettier/.prettierrc' }
          end,
        },
      },
    },
  },
}

-- vim: ts=2 sts=2 sw=2 et
