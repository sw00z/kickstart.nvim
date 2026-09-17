-- Scope-aware variable manager for hurl.nvim.
--
-- hurl.nvim only ever writes ~/.local/share/nvim/hurl-nvim/variables.json
-- (utils.save_persisted_vars is its single write path); env files are read-only
-- input. This adds the missing half: read/write/delete against the project's
-- vars.env, with an explicit scope prompt on create.
--
-- Runtime precedence is fixed by hurl itself: the plugin passes env files as
-- --variables-file and globals as --variable, and --variable always wins. So a
-- global of the same name silently shadows a project one.

local M = {}

local function load_plugin()
  local ok = pcall(function()
    require('lazy').load { plugins = { 'hurl.nvim' } }
  end)
  if not ok then
    pcall(require, 'hurl')
  end
  return require 'hurl.utils'
end

--- Project vars.env: beside the current .hurl buffer, else the first one the
--- plugin's own discovery already finds, else cwd.
---@return string
function M.env_path()
  local buf = vim.api.nvim_buf_get_name(0)
  if buf ~= '' and buf:match '%.hurl$' then
    return vim.fn.fnamemodify(buf, ':h') .. '/vars.env'
  end
  if _HURL_GLOBAL_CONFIG then
    for _, env in ipairs(_HURL_GLOBAL_CONFIG.find_env_files_in_folders()) do
      if vim.fn.filereadable(env.path) == 1 then
        return env.path
      end
    end
  end
  return vim.fn.getcwd() .. '/vars.env'
end

-- Same key=value grammar the plugin parses with, so what this shows is what
-- hurl receives.
local function read_env(path)
  local vars = {}
  if vim.fn.filereadable(path) == 0 then
    return vars
  end
  for _, line in ipairs(vim.fn.readfile(path)) do
    if not line:match '^%s*#' and line:match '%S' then
      local k, v = line:match '([^=]+)=(.+)'
      if k then
        vars[vim.trim(k)] = vim.trim(v)
      end
    end
  end
  return vars
end

--- Upsert or delete a key, preserving comments, ordering, and untouched lines.
--- Creates the file and its directory when absent. value == nil deletes.
local function write_env(path, name, value)
  local lines = vim.fn.filereadable(path) == 1 and vim.fn.readfile(path) or {}
  local out, found = {}, false
  for _, line in ipairs(lines) do
    local key = not line:match '^%s*#' and line:match '^%s*([^=]+)='
    if key and vim.trim(key) == name then
      found = true
      if value then
        table.insert(out, name .. '=' .. value)
      end
    else
      table.insert(out, line)
    end
  end
  if value and not found then
    table.insert(out, name .. '=' .. value)
  end
  vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
  vim.fn.writefile(out, path)
end

local function write_global(utils, name, value)
  local persisted = utils.load_persisted_vars()
  persisted[name] = value
  utils.save_persisted_vars(persisted)
  -- global_vars is what becomes --variable. Keep it to the persisted set only:
  -- the plugin's own manager merges env vars in here, which then go stale and
  -- override later edits to vars.env.
  _HURL_GLOBAL_CONFIG.global_vars = persisted
end

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = 'hurl vars' })
end

local function set_var(utils, scope, env_path, name, value)
  if scope == 'project' then
    write_env(env_path, name, value)
  else
    write_global(utils, name, value)
  end
  local where = scope == 'project' and vim.fn.fnamemodify(env_path, ':~:.') or 'variables.json'
  if value then
    notify(('set %s = %s in %s'):format(name, value, where))
  else
    notify(('deleted %s from %s'):format(name, where))
  end
end

local function prompt_new(utils, env_path)
  vim.ui.input({ prompt = 'Variable name: ' }, function(name)
    if not name or name == '' then
      return
    end
    name = vim.trim(name)
    vim.ui.input({ prompt = ('Value for %s: '):format(name) }, function(value)
      if not value or value == '' then
        return
      end
      vim.ui.select({ 'project', 'global' }, {
        prompt = ('Write %s to:'):format(name),
        format_item = function(scope)
          if scope == 'project' then
            local exists = vim.fn.filereadable(env_path) == 1
            return ('project  %s%s'):format(vim.fn.fnamemodify(env_path, ':~:.'), exists and '' or '  (will be created)')
          end
          return ('global   %s'):format(vim.fn.fnamemodify(utils.get_storage_path(), ':~'))
        end,
      }, function(scope)
        if scope then
          set_var(utils, scope, env_path, name, vim.trim(value))
        end
      end)
    end)
  end)
end

local function prompt_action(utils, env_path, item)
  vim.ui.select({ 'edit', 'delete' }, {
    prompt = ('%s (%s):'):format(item.name, item.scope),
  }, function(action)
    if action == 'edit' then
      vim.ui.input({ prompt = ('New value for %s: '):format(item.name), default = item.value }, function(value)
        if value and value ~= '' then
          set_var(utils, item.scope, env_path, item.name, vim.trim(value))
        end
      end)
    elseif action == 'delete' then
      set_var(utils, item.scope, env_path, item.name, nil)
    end
  end)
end

--- Entry point: list every variable with its scope, then act on one.
function M.manage()
  local utils = load_plugin()
  local env_path = M.env_path()
  local env_vars = read_env(env_path)
  local persisted = utils.load_persisted_vars()

  local items = {}
  for name, value in pairs(env_vars) do
    table.insert(items, {
      name = name,
      value = value,
      scope = 'project',
      shadowed = persisted[name] ~= nil,
    })
  end
  for name, value in pairs(persisted) do
    table.insert(items, { name = name, value = value, scope = 'global' })
  end
  table.sort(items, function(a, b)
    if a.name == b.name then
      return a.scope < b.scope
    end
    return a.name < b.name
  end)
  table.insert(items, { action = 'new' })

  vim.ui.select(items, {
    prompt = 'Hurl variables:',
    format_item = function(item)
      if item.action == 'new' then
        return '+ new variable'
      end
      -- Flag the shadowing case explicitly: the popup would otherwise show a
      -- project value that hurl is not actually using.
      local tag = item.shadowed and 'project, shadowed by global' or item.scope
      return ('%s = %s  [%s]'):format(item.name, item.value, tag)
    end,
  }, function(item)
    if not item then
      return
    end
    if item.action == 'new' then
      prompt_new(utils, env_path)
    else
      prompt_action(utils, env_path, item)
    end
  end)
end

return M
