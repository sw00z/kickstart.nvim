local M = {}

function M.read_json(path)
  local ok, result = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(path), '\n'))
  end)
  return ok and type(result) == 'table' and result or nil
end

function M.package_path(directory, name)
  if not name:match '^[@%w_.%-/]+$' or name:find('..', 1, true) then
    return nil
  end
  for dir in vim.fs.parents(directory .. '/_') do
    local path = dir .. '/node_modules/' .. name .. '/package.json'
    if vim.fn.filereadable(path) == 1 then
      return path
    end
    if vim.uv.fs_stat(dir .. '/.git') then
      break
    end
  end
end

function M.configure(name, cfg)
  local base = vim.lsp.config[name] or {}
  local base_attach, custom_attach = base.on_attach, cfg.on_attach
  if custom_attach then
    cfg.on_attach = function(client, bufnr)
      if base_attach then
        base_attach(client, bufnr)
      end
      custom_attach(client, bufnr)
    end
  end
  local before = cfg.before_init or base.before_init
  cfg.before_init = function(params, config)
    if before then
      before(params, config)
    end
    require('custom.lsp_profiles').prepare(config)
    if name == 'ts_ls' and config.root_dir then
      local sdk = M.package_path(config.root_dir, 'typescript')
      local path = sdk and vim.fs.dirname(sdk) .. '/lib/tsserver.js'
      if path and vim.fn.filereadable(path) == 1 then
        config.init_options = config.init_options or {}
        config.init_options.tsserver = config.init_options.tsserver or {}
        config.init_options.tsserver.path = path
        params.initializationOptions = config.init_options
      end
    end
  end
  if name == 'ts_ls' then
    cfg.root_dir = function(bufnr, on_dir)
      base.root_dir(bufnr, function(root)
        -- Separate package roots keep different SDKs and React declarations isolated.
        local package_root = vim.fs.root(bufnr, { 'package.json' })
        on_dir(package_root and vim.startswith(package_root .. '/', root .. '/') and package_root or root)
      end)
    end
    cfg.handlers = vim.tbl_extend('force', cfg.handlers or {}, {
      ['$/typescriptVersion'] = function(err, result, context)
        local client = vim.lsp.get_client_by_id(context.client_id)
        if client and not err then
          client.config._typescript_version = result
        end
      end,
    })
  elseif name == 'clangd' then
    local command = vim.deepcopy(cfg.cmd)
    cfg.cmd = function(dispatchers, config)
      local args = require('custom.lsp_profiles').clangd_command(command, config.root_dir)
      config._resolved_command = args
      return vim.lsp.rpc.start(args, dispatchers, { cwd = config.cmd_cwd, env = config.cmd_env, detached = config.detached })
    end
  end
  return cfg
end

function M.eslint_fix(bufnr)
  if #vim.lsp.get_clients { bufnr = bufnr, name = 'eslint' } == 0 then
    return
  end
  local ok, err = pcall(vim.api.nvim_buf_call, bufnr, function()
    vim.cmd 'LspEslintFixAll'
  end)
  if not ok then
    vim.notify('ESLint fixes failed: ' .. tostring(err), vim.log.levels.ERROR)
  end
end

function M.prettier_args(_, ctx)
  local fallback = vim.fn.expand '~/.config/prettier/.prettierrc'
  if vim.fn.filereadable(fallback) == 0 then
    return {}
  end
  local command = require('conform').get_formatter_info('prettier', ctx.buf).command
  if not command then
    return {}
  end
  local result = vim.system({ command, '--find-config-path', ctx.filename }, { text = true, cwd = ctx.dirname }):wait(2000)
  if result.code == 1 and vim.trim(result.stdout or '') == '' then
    return { '--config', fallback }
  end
  if result.code ~= 0 then
    vim.notify('Prettier configuration lookup failed; retaining native resolution', vim.log.levels.WARN)
  end
  return {}
end

function M.prettierd_env()
  local fallback = vim.fn.expand '~/.config/prettier/.prettierrc'
  return vim.fn.filereadable(fallback) == 1 and { PRETTIERD_DEFAULT_CONFIG = fallback } or {}
end

function M.context_lines(bufnr)
  local profiles = require 'custom.lsp_profiles'
  local root = profiles.root(bufnr)
  local lines = { '# Language context', '', 'Root: ' .. (root or 'none'), 'Profile: ' .. profiles.get(root) }
  for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
    local command = client.config._resolved_command or client.config.cmd
    local executable = type(command) == 'table' and vim.fn.exepath(command[1]) or nil
    if client.name == 'ts_ls' then
      local local_command = client.config.root_dir .. '/node_modules/.bin/typescript-language-server'
      executable = vim.fn.executable(local_command) == 1 and local_command or vim.fn.exepath 'typescript-language-server'
    end
    vim.list_extend(lines, { '', '## ' .. client.name, 'Root: ' .. (client.config.root_dir or 'none'), 'Executable: ' .. (executable or 'custom transport') })
    if type(command) == 'table' then
      lines[#lines + 1] = 'Arguments: ' .. table.concat(command, ' ')
    end
    if client.name == 'ts_ls' then
      local ts = client.config._typescript_version
      local sdk = ((client.config.init_options or {}).tsserver or {}).path
      lines[#lines + 1] = 'TypeScript: ' .. (ts and vim.inspect(ts) or 'version notification not received')
      lines[#lines + 1] = 'SDK: ' .. (sdk or 'server workspace/fallback resolution')
    elseif client.name == 'clangd' then
      local db = root and root .. '/compile_commands.json'
      lines[#lines + 1] = 'Compilation database at root: ' .. (db and vim.fn.filereadable(db) == 1 and db or 'not readable; inspect build/ and .clangd')
    end
  end
  local ok, conform = pcall(require, 'conform')
  if ok then
    lines[#lines + 1] = ''
    lines[#lines + 1] = 'Formatting owner: Conform; attached ESLint fixes run first on save'
    for _, formatter in ipairs(conform.list_formatters(bufnr)) do
      lines[#lines + 1] = ('Formatter: %s — %s'):format(
        formatter.name,
        formatter.available and (formatter.command or 'available') or (formatter.available_msg or 'unavailable')
      )
    end
  end
  local lint_ok, lint = pcall(require, 'lint')
  if lint_ok then
    lines[#lines + 1] = 'External lint: ' .. table.concat(lint.linters_by_ft[vim.bo[bufnr].filetype] or {}, ', ')
  end
  return lines
end

function M.setup()
  vim.api.nvim_create_user_command('LspContext', function()
    local lines = M.context_lines(vim.api.nvim_get_current_buf())
    vim.lsp.util.open_floating_preview(lines, 'markdown', { border = 'rounded', focusable = true, max_width = 110 })
  end, { desc = 'Inspect project language tools and analysis settings' })
end

return M
