-- Group only overloads with equivalent edits; preserve every server insertion.
local lsp_source = require 'cmp_nvim_lsp.source'

-- CompletionItemKind values that can legitimately have overloads.
local OVERLOADABLE = { [2] = true, [3] = true, [4] = true } -- Method, Function, Constructor

-- Marks an item this module synthesized (see resolve below). A private field, not
-- `detail`: cmp renders detail as its own fenced block ahead of the documentation
-- (entry.lua:515), so anything stored there is also shown to the user. cmp merges
-- rather than replaces the item table on resolve, so the field survives.
local MERGED_FLAG = '__clangd_overload_group'

-- clangd's OWN detail when it is left on `--completion-style=bundled`. We run it
-- on `detailed`, so this should never appear; the guard keeps a stray "[3
-- overloads]" from being mistaken for a return type if that flag ever changes.
local BUNDLED_DETAIL = '^%[%d+ overloads%]$'

local M = {}

-- Only presentation fields may differ inside a group. Unknown fields remain
-- part of the comparison so future protocol extensions fail conservatively.
local function payload(item)
  local value = vim.deepcopy(item)
  value.label = vim.trim(value.label or ''):match '^[^(]*'
  value.detail = nil
  value.documentation = nil
  if value.labelDetails then
    value.labelDetails.detail = nil
  end
  return value
end

---"void println(FILE *stream)" — assembled from three fields. clangd puts the
---return type in `detail`, and because cmp-nvim-lsp advertises labelDetailsSupport
---it puts the parameter list in `labelDetails.detail` rather than inlining it in
---`label`; reading only the label yields a bare "println" for every overload.
local function signature_of(item)
  local sig = vim.trim(item.label or '') .. ((item.labelDetails or {}).detail or '')
  local detail = item.detail
  if detail and detail ~= '' and not detail:match(BUNDLED_DETAIL) then
    sig = detail .. ' ' .. sig
  end
  return sig
end

---The single row that stands in for a whole overload set.
local function merge(first, sigs)
  local item = vim.deepcopy(first)
  -- Keep the label itself: LSP falls back to it when insertion text is absent.
  -- Cleared, not set to the count: cmp emits detail as a separate fenced block
  -- immediately above the documentation, so keeping a count here renders it twice.
  -- The count leads the signature block below instead.
  item.detail = nil
  item[MERGED_FLAG] = true
  -- Drop the inherited parameter list, or the row reads "println(…) (FILE *stream)"
  -- — one arbitrary overload's arguments beside a label that stands for all of them.
  item.labelDetails = nil

  -- One fenced block: the count as a C++ comment (so it highlights as one rather
  -- than sitting outside the syntax) followed by every distinct signature.
  local doc = { '```cpp', ('// %d overloads'):format(#sigs) }
  vim.list_extend(doc, sigs)
  table.insert(doc, '```')
  local original = first.documentation
  original = type(original) == 'table' and original.value or original
  if original and original ~= '' then
    table.insert(doc, '')
    table.insert(doc, original)
  end
  item.documentation = { kind = 'markdown', value = table.concat(doc, '\n') }
  return item
end

---Collapse overload sets in a completion response, preserving the server's order
---so cmp's own sorting still sees the ranking clangd intended.
local function group(response, can_resolve)
  if can_resolve then
    return response
  end
  local items = response and (response.items or response)
  if type(items) ~= 'table' or vim.tbl_isempty(items) then
    return response
  end

  local order, groups = {}, {}
  for _, item in ipairs(items) do
    local name = OVERLOADABLE[item.kind] and item.filterText or nil
    if not name or name == '' then
      table.insert(order, { item = item })
    else
      local key = tostring(item.kind) .. '\0' .. name
      groups[key] = groups[key] or {}
      local g
      local candidate = payload(item)
      for _, existing in ipairs(groups[key]) do
        if vim.deep_equal(existing.payload, candidate) then
          g = existing
          break
        end
      end
      if not g then
        g = { first = item, sigs = {}, payload = candidate }
        table.insert(groups[key], g)
        table.insert(order, { group = g })
      end
      table.insert(g.sigs, signature_of(item))
    end
  end

  local out = {}
  for _, slot in ipairs(order) do
    if slot.item then
      table.insert(out, slot.item)
    else
      local g = slot.group
      -- Index-based results (--all-scopes-completion) carry no parameter list, so a
      -- name can appear several times with an identical signature string. Those are
      -- duplicates, not overloads: emitting one untouched row collapses them without
      -- inventing a bogus "[2 overloads]" whose body repeats the same line twice.
      local unique, seen = {}, {}
      for _, sig in ipairs(g.sigs) do
        if not seen[sig] then
          seen[sig] = true
          table.insert(unique, sig)
        end
      end
      table.insert(out, #unique > 1 and merge(g.first, unique) or g.first)
    end
  end

  if response.items then
    response.items = out
    return response
  end
  return out
end

M.group = group

local wrapper = {}

function M.new()
  return setmetatable({}, { __index = wrapper })
end

-- cmp-nvim-lsp's source binds one client at construction; clangd restarts and
-- per-buffer differences mean the bound client can go stale, so rebuild on change.
function wrapper:_inner()
  local client = vim.lsp.get_clients({ bufnr = 0, name = 'clangd' })[1]
  if not client then
    self.inner = nil
    return nil
  end
  if not self.inner or self.inner.client ~= client then
    self.inner = lsp_source.new(client)
  end
  return self.inner
end

function wrapper:get_debug_name()
  return 'clangd_overloads'
end

function wrapper:is_available()
  local inner = self:_inner()
  return inner ~= nil and inner:is_available()
end

function wrapper:get_trigger_characters()
  local inner = self:_inner()
  return inner and inner:get_trigger_characters() or {}
end

function wrapper:get_keyword_pattern(params)
  local inner = self:_inner()
  if inner then
    return inner:get_keyword_pattern(params)
  end
  return require('cmp').get_config().completion.keyword_pattern
end

function wrapper:get_position_encoding_kind()
  local inner = self:_inner()
  return inner and inner:get_position_encoding_kind() or 'utf-16'
end

function wrapper:complete(params, callback)
  local inner = self:_inner()
  if not inner then
    return callback()
  end
  inner:complete(params, function(response)
    local provider = inner.client.server_capabilities.completionProvider
    local ok, result = pcall(group, response, provider and provider.resolveProvider)
    if not ok then
      vim.schedule(function()
        vim.notify('C++ overload grouping failed; using native completions: ' .. tostring(result), vim.log.levels.WARN)
      end)
    end
    callback(ok and result or response)
  end)
end

function wrapper:resolve(item, callback)
  -- Merged rows are synthetic: the server never issued them, and its reply would
  -- drop the overload list assembled above.
  if item[MERGED_FLAG] then
    return callback(item)
  end
  local inner = self:_inner()
  if not inner then
    return callback(item)
  end
  inner:resolve(item, callback)
end

function wrapper:execute(item, callback)
  local inner = self:_inner()
  if not inner then
    return callback(item)
  end
  inner:execute(item, callback)
end

return M
