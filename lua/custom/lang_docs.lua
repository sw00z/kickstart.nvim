-- <leader>Ld (browse) and <leader>Le (explore): the two documentation motions
-- that neither completion nor hover covers.
--
-- Ld answers "how do I use this library". Go is special-cased because gopls
-- serves package documentation itself through the `source.doc` code action; with
-- linksInHover='gopls' (see lspconfig.lua) that viewer documents the exact module
-- version in go.mod rather than whatever is newest on pkg.go.dev. Every other
-- filetype falls back to its DevDocs docset, seeded with the symbol under the
-- cursor.
--
-- Le answers "what is IN this import" — a question the protocol has no request
-- for. It resolves the import to the file that defines it, then opens the symbol
-- outline. textDocument/documentLink gives clangd the exact header path
-- (`#include <print>` -> /usr/include/c++/15/print); where the link is a web URL
-- rather than a file (gopls answers https://pkg.go.dev/strings),
-- textDocument/definition lands on the package source instead.

local M = {}

-- Docsets to search in addition to the filetype's own. nvim-devdocs maps
-- filetype -> alias 1:1 unless overridden in its filetypes.lua, so `cpp` already
-- resolves to the `cpp` docset; the gcc sets add the implementation-specific
-- pages (builtins, attributes, extensions) the language-standard sets omit.
local EXTRA_DOCSETS = {
  cpp = { 'gcc-14_cpp' },
  c = { 'gcc-14' },
}

local DOC_HEIGHT = 15

local function origin()
  local win, buf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
  local tick, cursor = vim.api.nvim_buf_get_changedtick(buf), vim.api.nvim_win_get_cursor(win)
  return {
    win = win,
    buf = buf,
    valid = function()
      return vim.api.nvim_win_is_valid(win)
        and vim.api.nvim_buf_is_valid(buf)
        and vim.api.nvim_get_current_win() == win
        and vim.api.nvim_win_get_buf(win) == buf
        and vim.api.nvim_buf_get_changedtick(buf) == tick
        and vim.deep_equal(vim.api.nvim_win_get_cursor(win), cursor)
    end,
  }
end

M.origin = origin

---The identifier under the cursor with any qualification stripped: DevDocs
---indexes `std::println` under `println`, so keeping the namespace loses every match.
local function cursor_symbol()
  return (vim.fn.expand '<cword>'):match '[%w_]+$' or ''
end

---Render `lines` as a docked Markdown buffer on the bottom edge, matching what
---custom/plugins/devdocs.lua produces for a picked doc — same devdocs_docked
---marker, so edgy's DevDocs slot captures it and it stacks with the other panels.
local function dock_markdown(lines, title)
  vim.cmd('botright split | resize ' .. DOC_HEIGHT)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_win_set_buf(0, buf)
  vim.bo[buf].filetype = 'markdown'
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = 'wipe'
  -- Naming is cosmetic (it labels the panel); a duplicate name is not worth failing on.
  pcall(vim.api.nvim_buf_set_name, buf, 'devdocs://' .. (title or 'doc'))
  vim.wo.wrap = true
  vim.wo.conceallevel = 2
  vim.b[buf].devdocs_docked = true
  vim.schedule(function()
    pcall(function()
      require('edgy.layout').update()
    end)
  end)
end

---Telescope picker over the DevDocs entry index for `aliases`, prefilled with
---`query`. Deliberately bypasses nvim-devdocs' own open_doc: that renders into
---the CURRENT window (its after_open hook only relocates when the devdocs.lua
---keymaps set an origin first), which would replace the code buffer you
---launched from.
local function devdocs_picker(aliases, query)
  local request_origin = origin()
  local ok_list, list = pcall(require, 'nvim-devdocs.list')
  local ok_ops, operations = pcall(require, 'nvim-devdocs.operations')
  if not (ok_list and ok_ops) then
    vim.notify('nvim-devdocs is not available', vim.log.levels.WARN)
    return
  end

  local entries = list.get_doc_entries(aliases)
  if not entries or vim.tbl_isempty(entries) then
    vim.notify(('No DevDocs docset installed for: %s (:DevdocsInstall)'):format(table.concat(aliases, ', ')), vim.log.levels.WARN)
    return
  end

  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local conf = require('telescope.config').values
  local previewers = require 'telescope.previewers'
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'

  pickers
    .new({}, {
      prompt_title = 'Reference docsets: ' .. table.concat(aliases, ', '),
      -- The seed. Ordinal is the bare entry name (not "[alias] name") so a
      -- symbol prefill matches the symbol, not the docset it came from.
      default_text = query,
      finder = finders.new_table {
        results = entries,
        entry_maker = function(e)
          return { value = e, display = ('[%s] %s'):format(e.alias, e.name), ordinal = e.name }
        end,
      },
      sorter = conf.generic_sorter {},
      previewer = previewers.new_buffer_previewer {
        define_preview = function(self, entry)
          self.state.doc_request = (self.state.doc_request or 0) + 1
          local sequence = self.state.doc_request
          operations.read_entry_async(entry.value, function(lines)
            -- Async: the preview buffer can be torn down before this returns.
            if sequence == self.state.doc_request and vim.api.nvim_buf_is_valid(self.state.bufnr) then
              vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
              vim.bo[self.state.bufnr].filetype = 'markdown'
            end
          end)
        end,
      },
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local sel = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if not sel then
            return
          end
          operations.read_entry_async(sel.value, function(lines)
            if request_origin.valid() then
              dock_markdown(lines, sel.value.name)
            end
          end)
        end)
        return true
      end,
    })
    :find()
end

---<leader>Ld — documentation for the symbol under the cursor.
function M.browse(reference_only)
  local ft = vim.bo.filetype

  if ft == 'go' and not reference_only then
    local client = vim.lsp.get_clients({ bufnr = 0, name = 'gopls' })[1]
    if not client then
      vim.notify('gopls is unavailable; opening Go reference docs', vim.log.levels.WARN)
      return M.browse(true)
    end
    local at = origin()
    local params = vim.lsp.util.make_range_params(at.win, client.offset_encoding)
    params.context = { only = { 'source.doc' }, diagnostics = {} }
    client:request('textDocument/codeAction', params, function(err, result)
      if not at.valid() then
        return
      end
      local actions = vim.tbl_filter(function(action)
        return not action.disabled
      end, result or {})
      if err or #actions == 0 then
        vim.notify('Package documentation unavailable; opening Go reference docs', vim.log.levels.WARN)
        return M.browse(true)
      end
      local function apply(action)
        if not action or not at.valid() then
          return
        end
        if action.edit then
          vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
        end
        local command = type(action.command) == 'table' and action.command or action
        client:exec_cmd(command, { bufnr = at.buf }, function(command_err)
          if command_err then
            vim.notify('Package documentation failed: ' .. command_err.message, vim.log.levels.WARN)
          end
        end)
      end
      if #actions == 1 then
        apply(actions[1])
      else
        vim.ui.select(actions, {
          prompt = 'Package documentation',
          format_item = function(action)
            return action.title
          end,
        }, apply)
      end
    end, at.buf)
    return
  end

  local ok_ft, ft_map = pcall(require, 'nvim-devdocs.filetypes')
  local mapped = (ok_ft and ft_map[ft]) or ft
  local aliases = type(mapped) == 'table' and vim.deepcopy(mapped) or { mapped }
  vim.list_extend(aliases, EXTRA_DOCSETS[ft] or {})
  devdocs_picker(aliases, cursor_symbol())
end

---Open the file behind `uri` and show its symbol outline.
local function open_outline(uri, line, column)
  local path = vim.uri_to_fname(uri)
  if vim.fn.filereadable(path) == 0 then
    vim.notify('Not readable: ' .. path, vim.log.levels.WARN)
    return
  end
  vim.cmd('edit ' .. vim.fn.fnameescape(path))
  local buf = vim.api.nvim_get_current_buf()
  if line then
    vim.api.nvim_win_set_cursor(0, { line, math.max(0, (column or 1) - 1) })
  end
  -- Aerial needs a backend attached; on a freshly opened stdlib header neither
  -- treesitter nor clangd has produced symbols yet at this point. focus=false
  -- keeps the cursor in the header — :AerialOpen jumps into the outline, which
  -- strands you in the sidebar of a file you have not looked at yet.
  vim.defer_fn(function()
    if vim.api.nvim_get_current_buf() ~= buf then
      return
    end
    pcall(function()
      require('aerial').open { focus = false }
    end)
  end, 200)
end

---Definition of the symbol under the cursor, then its outline. Used when the
---line carries no file-backed documentLink.
local function show_items(items, at, outline)
  if not at.valid() then
    return
  end
  if not items or #items == 0 then
    vim.notify('No source location available', vim.log.levels.INFO)
    return
  end
  local function select(item)
    if not item or not at.valid() then
      return
    end
    if outline then
      open_outline(vim.uri_from_fname(item.filename), item.lnum, item.col)
    else
      vim.lsp.util.show_document({
        uri = vim.uri_from_fname(item.filename),
        range = {
          start = { line = item.lnum - 1, character = item.col - 1 },
          ['end'] = { line = item.lnum - 1, character = item.col - 1 },
        },
      }, 'utf-8', { focus = true })
    end
  end
  if #items == 1 then
    select(items[1])
  else
    vim.ui.select(items, {
      prompt = 'Source locations',
      format_item = function(item)
        return ('%s:%d:%d %s'):format(item.filename, item.lnum, item.col, item.text or '')
      end,
    }, select)
  end
end

local function explore_via_definition(at, outline)
  at = at or origin()
  if not at.valid() then
    return
  end
  vim.lsp.buf.definition {
    on_list = function(res)
      show_items(res.items, at, outline)
    end,
  }
end

---<leader>Le — open what this import pulls in, and outline its symbols.
function M.explore()
  local at = origin()
  local bufnr = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1

  local client
  for _, c in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
    if c:supports_method 'textDocument/documentLink' then
      client = c
      break
    end
  end
  if not client then
    return explore_via_definition(at, true)
  end

  client:request('textDocument/documentLink', { textDocument = { uri = vim.uri_from_bufnr(bufnr) } }, function(err, result)
    vim.schedule(function()
      if not at.valid() then
        return
      end
      for _, link in ipairs((not err and result) or {}) do
        if link.target and link.range.start.line <= row and row <= link.range['end'].line then
          if vim.startswith(link.target, 'file://') then
            return open_outline(link.target)
          end
          -- A link exists but points at the web (gopls returns pkg.go.dev for
          -- imports). Its source file is the thing worth outlining, so stop
          -- scanning and let definition resolve it.
          break
        end
      end
      explore_via_definition(at, true)
    end)
  end, bufnr)
end

function M.source()
  local at = origin()
  local client = vim.lsp.get_clients({ bufnr = at.buf, name = 'ts_ls' })[1]
  if not client then
    return explore_via_definition(at, false)
  end
  local params = vim.lsp.util.make_position_params(at.win, client.offset_encoding)
  client:exec_cmd(
    { command = '_typescript.goToSourceDefinition', title = 'Source definition', arguments = { params.textDocument.uri, params.position } },
    { bufnr = at.buf },
    function(err, result)
      if not at.valid() then
        return
      end
      if err or not result or #result == 0 then
        return explore_via_definition(at, false)
      end
      show_items(vim.lsp.util.locations_to_items(result, client.offset_encoding), at, false)
    end
  )
end

function M.import_name()
  local ok, node = pcall(vim.treesitter.get_node)
  if ok then
    while node do
      if node:type() == 'import_statement' or node:type() == 'export_statement' then
        local source = node:field('source')[1]
        if source then
          return vim.treesitter.get_node_text(source, 0):sub(2, -2)
        end
      end
      node = node:parent()
    end
  end
  local line = vim.api.nvim_get_current_line()
  return line:match [[from%s*['"]([^'"]+)]]
    or line:match [[require%s*%(%s*['"]([^'"]+)]]
    or line:match [[import%s*%(%s*['"]([^'"]+)]]
    or line:match [[import%s*['"]([^'"]+)]]
end

function M.library()
  if vim.bo.filetype == 'go' then
    return M.browse()
  end
  if not vim.tbl_contains({ 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' }, vim.bo.filetype) then
    return M.browse(true)
  end
  local at = origin()
  local function open(name)
    if not name or name == '' or not at.valid() then
      return
    end
    if name:sub(1, 1) == '.' or name:sub(1, 1) == '/' then
      return M.source()
    end
    if name:match '^node:' then
      return devdocs_picker({ 'node' }, name:sub(6))
    end
    local package = name:match '^(@[^/]+/[^/]+)' or name:match '^([^/]+)'
    local tools = require 'custom.lsp_tools'
    local path = package and tools.package_path(vim.fs.dirname(vim.api.nvim_buf_get_name(at.buf)), package)
    local metadata = path and tools.read_json(path)
    if not metadata then
      vim.notify('Installed package metadata unavailable for ' .. name .. '; use :LspSource for aliases', vim.log.levels.WARN)
      return
    end
    local dir, options = vim.fs.dirname(path), {}
    for entry, kind in vim.fs.dir(dir) do
      if kind == 'file' and entry:lower():match '^readme' then
        options[#options + 1] = { label = 'Installed README: ' .. entry, path = dir .. '/' .. entry }
      end
    end
    local repository = type(metadata.repository) == 'table' and metadata.repository.url or metadata.repository
    for _, pair in ipairs { { 'Homepage', metadata.homepage }, { 'Repository', repository } } do
      if type(pair[2]) == 'string' then
        local url = pair[2]:gsub('^git%+', ''):gsub('^git://', 'https://'):gsub('^git@github.com:', 'https://github.com/'):gsub('%.git$', '')
        if url:match '^https?://' then
          options[#options + 1] = { label = pair[1] .. ': ' .. url, url = url }
        end
      end
    end
    if #options == 0 then
      vim.notify('No README or documentation URL declared by ' .. package, vim.log.levels.INFO)
      return
    end
    vim.ui.select(options, {
      prompt = ('%s %s — installed package; websites may describe newer versions'):format(package, metadata.version or '?'),
      format_item = function(item)
        return item.label
      end,
    }, function(item)
      if not item or not at.valid() then
        return
      end
      if item.path then
        dock_markdown(vim.fn.readfile(item.path), package .. '@' .. (metadata.version or '?'))
      else
        local _, err = vim.ui.open(item.url)
        if err then
          vim.notify(tostring(err), vim.log.levels.WARN)
        end
      end
    end)
  end
  local name = M.import_name()
  if name then
    open(name)
  else
    vim.ui.input({ prompt = 'Installed package name: ' }, open)
  end
end

local pinned_buffer
local hover_generation = 0
function M.pinned_hover(toggle)
  hover_generation = hover_generation + 1
  local generation = hover_generation
  local windows = pinned_buffer and vim.fn.win_findbuf(pinned_buffer) or {}
  if toggle and #windows > 0 then
    for _, win in ipairs(windows) do
      vim.api.nvim_win_close(win, true)
    end
    return
  end
  local at = origin()
  local clients = vim.lsp.get_clients { bufnr = at.buf, method = 'textDocument/hover' }
  if #clients == 0 then
    vim.notify('No hover provider attached', vim.log.levels.INFO)
    return
  end
  local pending, sections, requests, finished = #clients, {}, {}, false
  local function render()
    if finished or generation ~= hover_generation or not at.valid() then
      return
    end
    finished = true
    local lines = {}
    for _, provider in ipairs(clients) do
      if sections[provider.id] then
        if #lines > 0 then
          vim.list_extend(lines, { '', '---', '' })
        end
        vim.list_extend(lines, sections[provider.id])
      end
    end
    if #lines == 0 then
      vim.notify('No documentation at cursor', vim.log.levels.INFO)
      return
    end
    if not pinned_buffer or not vim.api.nvim_buf_is_valid(pinned_buffer) then
      pinned_buffer = vim.api.nvim_create_buf(false, true)
      vim.bo[pinned_buffer].filetype = 'nvim-docs-view'
      vim.treesitter.language.register('markdown', 'nvim-docs-view')
      vim.bo[pinned_buffer].bufhidden = 'hide'
      vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = pinned_buffer, desc = 'Close pinned documentation' })
    end
    vim.bo[pinned_buffer].modifiable = true
    vim.api.nvim_buf_set_lines(pinned_buffer, 0, -1, false, lines)
    vim.bo[pinned_buffer].modifiable = false
    if #vim.fn.win_findbuf(pinned_buffer) == 0 then
      vim.cmd 'botright 14split'
      vim.api.nvim_win_set_buf(0, pinned_buffer)
      vim.wo.wrap = true
      vim.wo.conceallevel = 2
      vim.api.nvim_set_current_win(at.win)
    end
  end
  for _, client in ipairs(clients) do
    local sent, id = client:request('textDocument/hover', vim.lsp.util.make_position_params(at.win, client.offset_encoding), function(err, result)
      if finished then
        return
      end
      requests[client.id] = nil
      pending = pending - 1
      if not err and result and result.contents then
        sections[client.id] = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
      end
      if pending == 0 then
        render()
      end
    end, at.buf)
    if sent then
      requests[client.id] = id
    else
      pending = pending - 1
    end
  end
  if pending == 0 then
    render()
  end
  vim.defer_fn(function()
    for _, client in ipairs(clients) do
      if requests[client.id] then
        client:cancel_request(requests[client.id])
      end
    end
    render()
  end, 3000)
end

function M.setup()
  vim.api.nvim_create_user_command('LspSource', M.source, { desc = 'Navigate to implementation source' })
  vim.api.nvim_create_user_command('LibraryDocs', M.library, { desc = 'Read installed package documentation' })
end

return M
