-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>Q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Quarto keymaps

local runner = require 'quarto.runner'
vim.keymap.set('n', '<localleader>rc', runner.run_cell, { desc = 'run cell', silent = true })
vim.keymap.set('n', '<localleader>ra', runner.run_above, { desc = 'run cell and above', silent = true })
vim.keymap.set('n', '<localleader>rA', runner.run_all, { desc = 'run all cells', silent = true })
vim.keymap.set('n', '<localleader>rl', runner.run_line, { desc = 'run line', silent = true })
vim.keymap.set('v', '<localleader>r', runner.run_range, { desc = 'run visual range', silent = true })
vim.keymap.set('n', '<localleader>rL', function()
  runner.run_all(true)
end, { desc = 'run all cells of all languages', silent = true })

-- Molten Keymaps
-- Initialize virtualenv for MoltenInit
vim.keymap.set('n', '<leader>mi', function()
  local venv = os.getenv 'VIRTUAL_ENV' or os.getenv 'CONDA_PREFIX'
  if venv ~= nil then
    -- in the form of /home/benlubas/.virtualenvs/VENV_NAME
    venv = string.match(venv, '/.+/(.+)')
    vim.cmd(('MoltenInit %s'):format(venv))
  else
    vim.cmd 'MoltenInit python3'
  end
end, { desc = 'Initialize Molten for python3', silent = true })

-- Zoxide Keymaps
-- Enter change directory mode
vim.keymap.set('n', '<leader>zi', ':Zi<CR>', { noremap = true, silent = true, desc = 'Enter zoxide mode' })

-- Notification keymaps (ui.nvim messages)
vim.keymap.set('n', '<leader>nd', '<cmd>UI clear<CR>', { desc = 'Dismiss notifications' })

vim.keymap.set('n', '<leader>ns', function()
  local ok, message = pcall(require, 'ui.message')
  if not ok then
    vim.notify('ui.nvim not loaded', vim.log.levels.WARN)
    return
  end

  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local previewers = require 'telescope.previewers'
  local conf = require('telescope.config').values

  -- Extract text from ui.nvim content fragments: [{attr_id, text}, ...]
  local function extract_text(content)
    if not content then
      return ''
    end
    local parts = {}
    for _, fragment in ipairs(content) do
      local text = fragment[2] or ''
      if text ~= '' then
        table.insert(parts, text)
      end
    end
    return table.concat(parts, '')
  end

  -- Build items from history (keyed by integer IDs, not a list)
  local items = {}
  for id, entry in pairs(message.history) do
    local raw_text = extract_text(entry.content)
    if raw_text ~= '' then
      -- Single-line version for the list display
      local display_text = raw_text:gsub('\n', ' '):gsub('%s+', ' '):gsub('^%s+', '')
      table.insert(items, {
        id = id,
        kind = entry.kind or '',
        type = entry.type or 'normal',
        text = display_text,
        full_text = raw_text, -- preserve original for preview
      })
    end
  end

  if #items == 0 then
    vim.notify('No messages in history', vim.log.levels.INFO)
    return
  end

  table.sort(items, function(a, b)
    return a.id > b.id
  end)

  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'

  pickers
    .new({}, {
      prompt_title = 'Message History  (<Space> mark, <CR> copy)',
      finder = finders.new_table {
        results = items,
        entry_maker = function(item)
          local kind_label = item.kind ~= '' and item.kind or 'msg'
          local icon_map = {
            emsg = ' ',
            echoerr = ' ',
            lua_error = ' ',
            rpc_error = ' ',
            shell_err = ' ',
            wmsg = ' ',
            write = ' ',
            search_count = ' ',
            quickfix = ' ',
            bufwrite = ' ',
          }
          local hl_map = {
            emsg = 'DiagnosticError',
            echoerr = 'DiagnosticError',
            lua_error = 'DiagnosticError',
            rpc_error = 'DiagnosticError',
            shell_err = 'DiagnosticError',
            wmsg = 'DiagnosticWarn',
            write = 'DiagnosticOk',
            bufwrite = 'DiagnosticOk',
            search_count = 'DiagnosticInfo',
            quickfix = 'DiagnosticInfo',
          }
          local icon = icon_map[item.kind] or '󰍡 '
          local hl = hl_map[item.kind] or 'DiagnosticHint'
          local prefix = icon .. kind_label:upper()
          local display = string.format('%s  %s', prefix, item.text)

          return {
            value = item,
            display = function(entry)
              return display, { { { 0, #prefix }, hl } }
            end,
            ordinal = item.text,
          }
        end,
      },
      sorter = conf.generic_sorter {},
      attach_mappings = function(prompt_bufnr, map)
        -- <Space> toggles multi-select
        map('i', '<Space>', actions.toggle_selection + actions.move_selection_worse)
        map('n', '<Space>', actions.toggle_selection + actions.move_selection_worse)

        -- <CR> copies selected messages (or current if none selected) to clipboard
        actions.select_default:replace(function()
          local picker = action_state.get_current_picker(prompt_bufnr)
          local selections = picker:get_multi_selection()

          -- Fall back to single entry under cursor if nothing selected
          if #selections == 0 then
            local entry = action_state.get_selected_entry()
            if entry then
              selections = { entry }
            end
          end

          actions.close(prompt_bufnr)

          if #selections == 0 then
            return
          end

          local texts = {}
          for _, sel in ipairs(selections) do
            local item = sel.value
            local kind_label = item.kind ~= '' and item.kind or 'msg'
            table.insert(texts, string.format('[%s] %s', kind_label:upper(), item.full_text or item.text))
          end

          local result = table.concat(texts, '\n')
          vim.fn.setreg('+', result)
          vim.notify(string.format('Copied %d message(s) to clipboard', #selections), vim.log.levels.INFO)
        end)

        return true
      end,
      previewer = previewers.new_buffer_previewer {
        title = 'Message Detail',
        define_preview = function(self, entry)
          local item = entry.value
          local bufnr = self.state.bufnr

          -- Header
          local kind_label = item.kind ~= '' and item.kind or 'msg'
          local header = string.format(' %s  %s', kind_label:upper(), item.type)

          -- Use the preview window width for the separator
          local win = self.state.winid
          local win_width = 40
          if win and vim.api.nvim_win_is_valid(win) then
            win_width = vim.api.nvim_win_get_width(win) - 2
          end
          local separator = string.rep('─', win_width)

          local lines = { header, separator, '' }

          -- Message body — use full_text to preserve original newlines
          local body = item.full_text or item.text
          for _, line in ipairs(vim.split(body, '\n', { plain = true })) do
            -- Soft-wrap long lines to fit the preview window
            if #line > win_width then
              while #line > win_width do
                table.insert(lines, ' ' .. line:sub(1, win_width))
                line = line:sub(win_width + 1)
              end
              if #line > 0 then
                table.insert(lines, ' ' .. line)
              end
            else
              table.insert(lines, ' ' .. line)
            end
          end

          vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
          vim.bo[bufnr].filetype = ''

          -- Highlight the header based on message kind
          local kind_hl = ({
            emsg = 'DiagnosticError',
            echoerr = 'DiagnosticError',
            lua_error = 'DiagnosticError',
            rpc_error = 'DiagnosticError',
            shell_err = 'DiagnosticError',
            wmsg = 'DiagnosticWarn',
            write = 'DiagnosticOk',
            search_count = 'DiagnosticInfo',
            quickfix = 'DiagnosticInfo',
          })[item.kind] or 'DiagnosticHint'

          local ns = vim.api.nvim_create_namespace 'telescope_msg_preview'
          vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

          -- Kind label highlight
          pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, 0, 0, {
            end_col = #lines[1],
            hl_group = kind_hl,
          })
          -- Separator
          pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, 1, 0, {
            end_col = #lines[2],
            hl_group = 'Comment',
          })

          -- Body lines colored by kind
          local body_hl = ({
            emsg = 'UIMessageError',
            echoerr = 'UIMessageError',
            lua_error = 'UIMessageError',
            rpc_error = 'UIMessageError',
            shell_err = 'UIMessageError',
            wmsg = 'UIMessageWarn',
            write = 'UIMessageOk',
          })[item.kind]

          if body_hl then
            for i = 2, #lines - 1 do
              pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, i, 0, {
                end_col = #lines[i + 1],
                hl_group = body_hl,
              })
            end
          end
        end,
      },
    })
    :find()
end, { desc = 'Search notification history' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
-- vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
-- vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
-- vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
-- vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

vim.keymap.set('n', '<C-w>n', ':tabNext<CR>', { desc = 'Move focus to the next window tab' })
vim.keymap.set('n', '<C-w>X', ':tabclose<CR>', { desc = 'close the window tab' })
vim.keymap.set('n', '<C-w>N', ':tabnew<CR>', { desc = 'Create new window tab' })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- vim: ts=2 sts=2 sw=2 et
