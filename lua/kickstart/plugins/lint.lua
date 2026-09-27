return {

  { -- Linting
    'mfussenegger/nvim-lint',
    cmd = { 'Lint' },
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'
      lint.linters_by_ft = {
        markdown = { 'markdownlint' },
        dockerfile = { 'hadolint' },
        terraform = { 'tflint' },
        text = { 'vale' },
        go = { 'golangcilint' },
        python = { 'ruff' },
        -- C/C++ linting handled by clangd's --clang-tidy integration
        -- (see lua/kickstart/plugins/lspconfig.lua clangd cmd flags).
        sh = { 'shellcheck' },
        bash = { 'shellcheck' },
        -- New languages (Phase 4)
        sql = { 'sqlfluff' },
        kotlin = { 'ktlint' },
      }

      -- To allow other plugins to add linters to require('lint').linters_by_ft,
      -- instead set linters_by_ft like this:
      -- lint.linters_by_ft = lint.linters_by_ft or {}
      -- lint.linters_by_ft['markdown'] = { 'markdownlint' }
      --
      -- However, note that this will enable a set of default linters,
      -- which will cause errors unless these tools are available:
      -- {
      --   clojure = { "clj-kondo" },
      --   inko = { "inko" },
      --   janet = { "janet" },
      --   markdown = { "vale" },
      --   rst = { "vale" },
      --   ruby = { "ruby" },
      --   terraform = { "tflint" },
      --   text = { "vale" }
      -- }
      --
      -- You can disable the default linters by setting their filetypes to nil:
      -- lint.linters_by_ft['clojure'] = nil
      -- lint.linters_by_ft['dockerfile'] = nil
      -- lint.linters_by_ft['inko'] = nil
      -- lint.linters_by_ft['janet'] = nil
      -- lint.linters_by_ft['json'] = nil
      -- lint.linters_by_ft['markdown'] = nil
      -- lint.linters_by_ft['rst'] = nil
      -- lint.linters_by_ft['ruby'] = nil
      -- lint.linters_by_ft['terraform'] = nil
      -- lint.linters_by_ft['text'] = nil

      -- Lint on save only; <leader>f (conform.lua) runs :Lint after formatting.
      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      local go_processes = {}
      local function run_go(bufnr)
        if go_processes[bufnr] then
          go_processes[bufnr]:cancel()
        end
        local linter = vim.deepcopy(lint.linters.golangcilint)
        linter.name = 'golangcilint'
        local root = vim.fs.root(bufnr, { 'go.mod', 'go.work' }) or vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
        if not linter.args then
          vim.notify('golangci-lint arguments unavailable; check :Mason and the Go toolchain', vim.log.levels.WARN)
          return
        end
        -- The upstream linter caches its module check at load time, before our cwd is set.
        local filename = vim.api.nvim_buf_get_name(bufnr)
        linter.args[#linter.args] = vim.fs.root(bufnr, { 'go.mod' }) and vim.fs.dirname(filename) or filename
        local ok, proc = pcall(lint.lint, linter, { cwd = root })
        go_processes[bufnr] = ok and proc or nil
        if not ok then
          vim.notify('Go lint failed: ' .. tostring(proc), vim.log.levels.WARN)
        end
      end
      vim.api.nvim_create_autocmd('BufWritePost', {
        group = lint_augroup,
        callback = function(event)
          -- Only run the linter in buffers that you can modify in order to
          -- avoid superfluous noise, notably within the handy LSP pop-ups that
          -- describe the hovered symbol using Markdown.
          if vim.bo[event.buf].filetype == 'go' then
            if require('custom.lsp_profiles').for_buffer(event.buf) == 'balanced' then
              return
            end
            if vim.bo[event.buf].modifiable and vim.bo[event.buf].buftype == '' then
              run_go(event.buf)
            end
            return
          end
          if vim.bo[event.buf].modifiable and vim.bo[event.buf].buftype == '' then
            lint.try_lint()
          end
        end,
      })
      vim.api.nvim_create_user_command('Lint', function()
        if vim.bo.filetype == 'go' then
          run_go(vim.api.nvim_get_current_buf())
        else
          lint.try_lint()
        end
      end, { desc = 'Run configured external linters' })
      vim.api.nvim_create_autocmd('User', {
        group = lint_augroup,
        pattern = 'LspProfileChanged',
        callback = function(event)
          if event.data.profile ~= 'balanced' then
            return
          end
          for bufnr, proc in pairs(go_processes) do
            if require('custom.lsp_profiles').root(bufnr) == event.data.root then
              proc:cancel()
              go_processes[bufnr] = nil
              vim.diagnostic.reset(lint.get_namespace 'golangcilint', bufnr)
            end
          end
        end,
      })
      vim.api.nvim_create_autocmd('BufWipeout', {
        group = lint_augroup,
        callback = function(event)
          if go_processes[event.buf] then
            go_processes[event.buf]:cancel()
          end
          go_processes[event.buf] = nil
        end,
      })
    end,
  },
}
