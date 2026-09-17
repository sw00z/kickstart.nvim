-- Telescope ⇄ Zeal offline docs (Lua port of ivan-cukic/nvim-telescope-zeal-cli).
-- Two-stage flow, both stages in Telescope:
--   1. pick_docset() — fuzzy-pick WHICH docset from every installed .docset,
--      auto-scanned from the Zeal data dir (no hand-maintained list).
--   2. show(docset)  — fuzzy-pick a PAGE inside it (preview on the side), then
--      render the chosen page into a bottom split that edgy captures into its
--      "Zeal" slot — same bottom-dock UX as the DevDocs panels.
--
-- Backed by `zeal-cli` on $PATH (Python venv script). `zeal-cli DOCSET` lists the
-- page names. For single-file docsets (Zig, etc.) an index entry is a #fragment of
-- one shared page; zeal-cli slices out just that section so each entry shows its
-- own part. The picker previews the section as plain Markdown (--format=md, no
-- glow); on select, glow renders that same Markdown into the docked panel. glow
-- runs only for the chosen page, never per preview.
local M = {}

local parameters = {}

function M.setup(opts)
  parameters = opts or {}
end

-- Zeal keeps docsets under $XDG_DATA_HOME/Zeal/Zeal/docsets (mirrors zeal-cli's
-- xdg.xdg_data_home()). Override with setup({ docsets_dir = ... }).
local function default_docsets_dir()
  local data = vim.env.XDG_DATA_HOME
  if not data or data == '' then
    data = (vim.env.HOME or '') .. '/.local/share'
  end
  return vim.fs.normalize(data .. '/Zeal/Zeal/docsets')
end

-- Dir-name (the zeal-cli argv) → readable label: underscores to spaces. A
-- documentation_sets[key].title entry overrides this for hand-tuned names.
local function shorten(key)
  return (key:gsub('_', ' '))
end

function M.docset_title(key)
  local cfg = (parameters.documentation_sets or {})[key]
  return (cfg and cfg.title) or shorten(key)
end

-- Every installed docset as { key = <dir-name sans .docset>, title = <label> },
-- sorted by label. key is exactly what zeal-cli expects as its docset argument.
function M.list_docsets()
  local dir = parameters.docsets_dir or default_docsets_dir()
  local out = {}
  for name, typ in vim.fs.dir(dir) do
    if typ == 'directory' and name:sub(-7) == '.docset' then
      local key = name:sub(1, -8)
      out[#out + 1] = { key = key, title = M.docset_title(key) }
    end
  end
  table.sort(out, function(a, b)
    return a.title:lower() < b.title:lower()
  end)
  return out
end

-- A finished terminal job leaves a trailing "[Process exited N]" line (plus the
-- blank rows the terminal pads to window height). The buffer becomes editable once
-- the job dies, so trim those trailing lines — glow's rendered content above is
-- untouched. Called a few times because the notice lands a tick or two after
-- on_exit fires.
local function strip_exit_notice(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.bo[buf].modifiable = true
  local n = vim.api.nvim_buf_line_count(buf)
  while n > 0 do
    local line = vim.api.nvim_buf_get_lines(buf, n - 1, n, false)[1] or ''
    if line == '' or line:match '^%[Process exited %d+%]%s*$' then
      vim.api.nvim_buf_set_lines(buf, n - 1, n, false, {})
      n = n - 1
    else
      break
    end
  end
  vim.bo[buf].modifiable = false
end

-- Render the chosen entry into the bottom Zeal panel. zeal-cli --format=md slices
-- the entry's section to Markdown; glow styles it in a terminal buffer (the same
-- renderer as the DevDocs panels). glow runs ONLY here, on select — the picker
-- preview is plain Markdown (no glow). A blank section is skipped (some #fragments
-- resolve to an anchor with no body; opening it would just show "[Process exited]").
local function open_docked(what, page)
  local md = vim.fn.systemlist { 'zeal-cli', '--format=md', what, page }
  local has_text = false
  for _, l in ipairs(md) do
    if l:match '%S' then
      has_text = true
      break
    end
  end
  if not has_text then
    vim.notify(("Zeal: '%s' has no content"):format(page), vim.log.levels.WARN)
    return
  end
  -- glow renders a file; write the sliced markdown to a temp .md, then clean it up.
  local tmp = vim.fn.tempname() .. '.md'
  vim.fn.writefile(md, tmp)
  vim.cmd 'botright split | resize 15'
  vim.cmd 'enew'
  local buf = vim.api.nvim_get_current_buf()
  -- PREVIOUS RENDERER (glow → ANSI in a terminal buffer). Replaced because glow
  -- renders to fixed-width text once, so the panel could not reflow, and the
  -- output was neither selectable nor searchable. Kept for reference.
  -- local wrap_at = tostring(math.max(40, vim.api.nvim_win_get_width(0) - 2))
  -- vim.fn.jobstart({ 'glow', '-s', 'dark', '-w', wrap_at, tmp }, {
  --   term = true,
  --   on_exit = function()
  --     for _, delay in ipairs { 50, 200, 500 } do
  --       vim.defer_fn(function()
  --         strip_exit_notice(buf)
  --       end, delay)
  --     end
  --   end,
  -- })
  -- vim.bo[buf].filetype = 'glow'

  -- Load the Markdown straight into the buffer: render-markdown.nvim styles it in
  -- place (the same renderer as LSP hover), so the text stays selectable,
  -- searchable, and reflows with the window. strip_exit_notice still earns its
  -- keep here by trimming the trailing blank lines zeal-cli emits.
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, md)
  strip_exit_notice(buf)
  vim.wo.wrap = true
  vim.wo.conceallevel = 2 -- render-markdown conceals the raw markup it replaces
  vim.b[buf].zeal_docked = true -- route to the Zeal slot (ft='markdown' is shared)
  vim.bo[buf].filetype = 'markdown'
  vim.cmd 'stopinsert'
  vim.defer_fn(function()
    vim.fn.delete(tmp)
  end, 3000)
  vim.schedule(function()
    pcall(function()
      require('edgy.layout').update()
    end)
  end)
end

-- Stage 2: page picker inside a single docset.
local function show_impl(what)
  local previewers = require 'telescope.previewers'
  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'
  local conf = require('telescope.config').values

  pickers
    .new({}, {
      prompt_title = 'Zeal: ' .. M.docset_title(what),
      finder = finders.new_oneshot_job { 'zeal-cli', what },
      sorter = conf.generic_sorter {},
      -- Plain-Markdown preview (NOT glow): the entry's sliced section as Markdown,
      -- highlighted by the markdown filetype. A buffer previewer (vim.system, async)
      -- captures the text into a NORMAL buffer — unlike a terminal previewer it never
      -- leaves a "[Process exited]" line, and arrowing the list never blocks.
      previewer = previewers.new_buffer_previewer {
        title = 'Zeal preview',
        define_preview = function(self, entry)
          local bufnr = self.state.bufnr
          vim.system({ 'zeal-cli', '--format=md', what, entry.value }, { text = true }, function(res)
            vim.schedule(function()
              if not vim.api.nvim_buf_is_valid(bufnr) then
                return
              end
              local out = vim.split((res.stdout or ''):gsub('%s+$', ''), '\n')
              vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, out)
              vim.bo[bufnr].filetype = 'markdown'
            end)
          end)
        end,
      },
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection then
            open_docked(what, selection.value)
          end
        end)
        return true
      end,
    })
    :find()
end

function M.show(what)
  show_impl(what)
end

-- Stage 1: pick which docset, then hand off to show().
function M.pick_docset()
  local docsets = M.list_docsets()
  if vim.tbl_isempty(docsets) then
    vim.notify('telescope_zeal: no .docset dirs under ' .. (parameters.docsets_dir or default_docsets_dir()), vim.log.levels.WARN)
    return
  end

  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'
  local conf = require('telescope.config').values

  pickers
    .new({}, {
      prompt_title = 'Zeal docsets',
      finder = finders.new_table {
        results = docsets,
        entry_maker = function(d)
          return { value = d.key, display = d.title, ordinal = d.title .. ' ' .. d.key }
        end,
      },
      sorter = conf.generic_sorter {},
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection then
            M.show(selection.value)
          end
        end)
        return true
      end,
    })
    :find()
end

return M
