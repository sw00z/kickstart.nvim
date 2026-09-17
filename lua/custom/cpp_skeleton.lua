local M = {}

local keywords = {}
for word in
  ('alignas alignof and and_eq asm auto bitand bitor bool break case catch char char8_t char16_t char32_t class compl concept const consteval constexpr constinit const_cast continue co_await co_return co_yield decltype default delete do double dynamic_cast else enum explicit export extern false float for friend goto if inline int long mutable namespace new noexcept not not_eq nullptr operator or or_eq private protected public register reinterpret_cast requires return short signed sizeof static static_assert static_cast struct switch template this thread_local throw true try typedef typeid typename union unsigned using virtual void volatile wchar_t while xor xor_eq'):gmatch '%S+'
do
  keywords[word] = true
end

function M.identifier(name)
  return type(name) == 'string' and name:match '^[A-Za-z][A-Za-z0-9_]*$' ~= nil and not keywords[name] and not name:find('__', 1, true)
end

function M.namespace(name)
  if name == '' then
    return true
  end
  for _, part in ipairs(vim.split(name, '::', { plain = true })) do
    if not M.identifier(part) then
      return false
    end
  end
  return true
end

---@param opts {kind: string, class?: string, namespace?: string, include?: string}
---@return string[]? lines
---@return string? error
function M.render(opts)
  local ns = opts.namespace or ''
  if not M.namespace(ns) then
    return nil, 'Use a namespace such as engine::net, or leave it empty'
  end
  local lines
  if opts.kind == 'header' then
    if not M.identifier(opts.class) then
      return nil, 'Choose a valid, non-reserved C++ class name'
    end
    lines = { '#pragma once', '' }
  elseif opts.kind == 'source' then
    local inc = opts.include or ''
    if inc == '' or inc:find '["\r\n<>]' then
      return nil, 'Enter a quoted-header path without quotes'
    end
    lines = { '#include "' .. inc .. '"', '' }
  elseif opts.kind == 'main' then
    return { 'int main() {', '  return 0;', '}' }
  else
    return nil, 'Supported files: .h, .hpp, .hh, .hxx, .cpp, .cc, .cxx'
  end
  if ns ~= '' then
    vim.list_extend(lines, { 'namespace ' .. ns .. ' {', '' })
  end
  if opts.kind == 'header' then
    vim.list_extend(lines, { 'class ' .. opts.class .. ' {', 'public:', '', 'private:', '', '};' })
  else
    lines[#lines + 1] = ''
  end
  if ns ~= '' then
    vim.list_extend(lines, { '', '} // namespace ' .. ns })
  end
  return lines
end

function M.insert()
  local buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  local original = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  if name == '' or vim.bo[buf].buftype ~= '' or not vim.bo[buf].modifiable or #original ~= 1 or original[1] ~= '' then
    vim.notify('Skel requires a named, empty, editable buffer', vim.log.levels.WARN)
    return
  end
  local ext, stem = vim.fn.fnamemodify(name, ':e'), vim.fn.fnamemodify(name, ':t:r')
  local kind = ({ h = 'header', hpp = 'header', hh = 'header', hxx = 'header', cpp = 'source', cc = 'source', cxx = 'source' })[ext]
  if not kind then
    vim.notify('Skel supports C++ headers and sources', vim.log.levels.WARN)
    return
  end
  if kind == 'source' and stem:lower() == 'main' then
    kind = 'main'
  end
  local opts = { kind = kind }
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local function apply()
    if not vim.api.nvim_buf_is_valid(buf) or vim.api.nvim_buf_get_changedtick(buf) ~= tick then
      vim.notify('Skel cancelled: buffer changed while prompting', vim.log.levels.WARN)
      return
    end
    local lines, err = M.render(opts)
    if not lines then
      vim.notify(err, vim.log.levels.WARN)
      return
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.b[buf].cpp_namespace = opts.namespace
  end
  local function namespace()
    vim.ui.input({ prompt = 'Namespace (empty for global): ', default = vim.b[buf].cpp_namespace or '' }, function(value)
      if value == nil then
        return
      end
      opts.namespace = value
      apply()
    end)
  end
  if kind == 'main' then
    apply()
    return
  end
  if kind == 'header' then
    vim.ui.input({ prompt = 'Class name: ', default = stem }, function(value)
      if value == nil then
        return
      end
      opts.class = value
      namespace()
    end)
  else
    local suggested = stem .. '.hpp'
    for _, header_ext in ipairs { 'hpp', 'h', 'hh', 'hxx' } do
      if vim.fn.filereadable(vim.fn.fnamemodify(name, ':r') .. '.' .. header_ext) == 1 then
        suggested = stem .. '.' .. header_ext
        break
      end
    end
    vim.ui.input({ prompt = 'Header include path (relative to an include directory): ', default = suggested }, function(value)
      if value == nil then
        return
      end
      opts.include = value
      namespace()
    end)
  end
end

return M
