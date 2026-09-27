-- yanky.nvim: yank history ring. Normal-mode p/P open it in Telescope and paste the chosen entry.
-- The ring holds Windows clipboard text, so it lives in memory for the session and never reaches shada.

-- The ring records Neovim yanks; text copied in Windows joins it when p/P reads '+'.
local function push_clipboard()
  local info = require('yanky.utils').get_register_info '+'
  if info and info.regcontents ~= '' then
    require('yanky.history').push(info)
  end
end

-- The chosen entry becomes the clipboard and the newest ring entry, so `.` and the next p repeat it.
local function put_selection(type, count)
  return function(prompt_bufnr)
    local entry = require('telescope.actions.state').get_selected_entry()
    require('telescope.actions').close(prompt_bufnr)
    if not entry then
      return
    end
    local item = entry.value
    -- Runs after Telescope returns focus to the editing window.
    vim.schedule(function()
      if item.history_index > 1 then
        local history = require 'yanky.history'
        history.delete(item.history_index)
        history.push(item)
      end
      vim.fn.setreg('+', item.regcontents, item.regtype)
      vim.cmd.normal { count .. type, bang = true }
    end)
  end
end

local function put(type)
  return function()
    local register, count = vim.v.register, vim.v.count1
    -- Named registers, macros and read-only buffers keep the native put; a picker would stall macro replay.
    if register ~= require('yanky.utils').get_default_register() or vim.fn.reg_recording() ~= '' or vim.fn.reg_executing() ~= '' or not vim.bo.modifiable then
      vim.cmd.normal { ('"%s%d%s'):format(register, count, type), bang = true }
      return
    end
    push_clipboard()
    require('telescope').load_extension 'yank_history'
    require('telescope').extensions.yank_history.yank_history {
      prompt_title = type == 'p' and 'Paste after' or 'Paste before',
      attach_mappings = function()
        require('telescope.actions').select_default:replace(put_selection(type, count))
        return true
      end,
    }
  end
end

return {
  'gbprod/yanky.nvim',
  -- Load before the first yank; the ring only records yanks made after setup().
  event = 'VeryLazy',
  keys = {
    { 'p', put 'p', desc = 'Paste after (pick from yank history)' },
    { 'P', put 'P', desc = 'Paste before (pick from yank history)' },
  },
  opts = {
    -- shada storage and numbered-register sync would write copied passwords to main.shada in plain text.
    ring = { storage = 'memory', sync_with_numbered_registers = false },
    -- keymaps.lua already highlights yanks on TextYankPost.
    highlight = { on_yank = false },
    -- Default true reads '+' on every FocusLost and FocusGained.
    system_clipboard = { sync_with_ring = false },
  },
}
