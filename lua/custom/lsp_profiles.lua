local M = {}
local choices
local state_path = vim.fn.stdpath 'state' .. '/lsp-profiles.json'
local primary = { clangd = 1, gopls = 2, ts_ls = 3 }

local function normalize(root)
  return root and vim.fs.normalize(vim.uv.fs_realpath(root) or root) or nil
end

function M.root(bufnr)
  local clients = vim.lsp.get_clients { bufnr = bufnr or 0 }
  table.sort(clients, function(a, b)
    return (primary[a.name] or 99) < (primary[b.name] or 99)
  end)
  for _, client in ipairs(clients) do
    if client.config.root_dir then
      return normalize(client.config.root_dir)
    end
  end
  return normalize(vim.fs.root(bufnr or 0, { '.clangd', 'go.work', 'go.mod', 'package.json', '.git' }))
end

local function read_choices()
  if choices then
    return choices
  end
  choices = {}
  if vim.fn.filereadable(state_path) == 0 then
    return choices
  end
  local ok, value = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(state_path), '\n'))
  end)
  if ok and type(value) == 'table' and value.version == 1 and type(value.projects) == 'table' then
    for root, profile in pairs(value.projects) do
      if type(root) ~= 'string' or root:sub(1, 1) ~= '/' or (profile ~= 'full' and profile ~= 'balanced') then
        ok = false
        break
      end
    end
    if ok then
      choices = value.projects
      return choices
    end
  end
  vim.notify('Invalid LSP profile state; using full defaults: ' .. state_path, vim.log.levels.WARN)
  return choices
end

function M.get(root)
  return read_choices()[normalize(root) or ''] or 'full'
end

function M.for_buffer(bufnr)
  return M.get(M.root(bufnr))
end

function M.clangd_command(command, root)
  local result = {}
  for _, arg in ipairs(command) do
    if not arg:match '^%-%-clang%-tidy' and not arg:match '^%-j=' and not arg:match '^%-%-limit%-results=' then
      result[#result + 1] = arg
    end
  end
  local full = M.get(root) == 'full'
  vim.list_extend(result, { '--clang-tidy=' .. tostring(full), '-j=' .. (full and '8' or '2'), '--limit-results=' .. (full and '300' or '100') })
  return result
end

function M.prepare(config)
  if config.name == 'gopls' then
    config.settings = config.settings or {}
    config.settings.gopls = config.settings.gopls or {}
    config.settings.gopls.staticcheck = M.get(config.root_dir) == 'full'
  end
end

local function restart(client)
  local config, buffers = vim.deepcopy(client.config), vim.tbl_keys(client.attached_buffers)
  client:stop()
  local attempts = 0
  local function start()
    attempts = attempts + 1
    if not client:is_stopped() then
      if attempts == 30 then
        client:stop(true)
      end
      if attempts < 50 then
        vim.defer_fn(start, 100)
      else
        vim.notify('clangd did not stop; restart it manually with :LspRestart', vim.log.levels.ERROR)
      end
      return
    end
    for _, bufnr in ipairs(buffers) do
      if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
        vim.lsp.start(config, { bufnr = bufnr })
      end
    end
  end
  vim.defer_fn(start, 100)
end

function M.set(root, profile)
  root = normalize(root)
  if not root then
    return false, 'Open a file in a language-server project first'
  end
  if profile ~= 'full' and profile ~= 'balanced' and profile ~= 'reset' then
    return false, 'Expected full, balanced, or reset'
  end
  local updated = vim.deepcopy(read_choices())
  updated[root] = profile ~= 'reset' and profile or nil
  local temp = state_path .. '.' .. vim.fn.getpid() .. '.tmp'
  local ok, err = pcall(function()
    vim.fn.mkdir(vim.fs.dirname(state_path), 'p')
    assert(vim.fn.writefile({ vim.json.encode { version = 1, projects = updated } }, temp) == 0)
    assert(vim.uv.fs_rename(temp, state_path))
  end)
  if not ok then
    return false, 'Could not save LSP profile: ' .. tostring(err)
  end
  choices = updated
  for _, client in ipairs(vim.lsp.get_clients()) do
    if normalize(client.config.root_dir) == root then
      if client.name == 'clangd' then
        restart(client)
      else
        if client.name == 'gopls' then
          M.prepare(client.config)
          client:notify('workspace/didChangeConfiguration', { settings = client.config.settings })
        end
        for bufnr in pairs(client.attached_buffers) do
          require('custom.lsp_attach').refresh(bufnr, nil, true)
        end
      end
    end
  end
  vim.api.nvim_exec_autocmds('User', { pattern = 'LspProfileChanged', data = { root = root, profile = M.get(root) } })
  return true
end

function M.setup()
  vim.api.nvim_create_user_command('LspProfile', function(opts)
    local root = M.root()
    if opts.args ~= '' then
      local ok, err = M.set(root, opts.args)
      if not ok then
        vim.notify(err, vim.log.levels.ERROR)
        return
      end
    end
    vim.notify(('LSP profile: %s\n%s'):format(M.get(root), root or 'No project root'))
  end, {
    nargs = '?',
    complete = function()
      return { 'full', 'balanced', 'reset' }
    end,
    desc = 'Show or select the persistent project analysis profile',
  })
end

return M
