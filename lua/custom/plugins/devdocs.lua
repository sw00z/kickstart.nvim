return {
  'luckasRanarison/nvim-devdocs',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  config = function()
    -- glow word-wraps at a fixed width and cannot read the pty size itself —
    -- rendering is byte-for-byte identical at 60 and 140 columns — so the width
    -- must be passed or nothing wraps at all. These panels span the full editor
    -- width, where a hardcoded 80 left most of the panel empty and broke tables
    -- and code blocks. `win` reads the real window; nil falls back to the editor.
    -- Unused since the panels render Markdown natively; kept for reference.
    -- local function glow_args(win)
    --   local cols = win and vim.api.nvim_win_get_width(win) or vim.o.columns
    --   return { '-s', 'dark', '-w', tostring(math.max(40, cols - 2)) }
    -- end

    -- Mark a buffer (already sitting in its own bottom split) as a docked DevDocs
    -- doc, then nudge edgy to capture it. edgy's bottom DevDocs slot matches the
    -- marker ONLY — never the telescope preview (also ft='glow', but it carries no
    -- marker) — so the preview stays on the right during search.
    local function mark_docked(bufnr)
      vim.b[bufnr].devdocs_docked = true
      vim.schedule(function()
        pcall(function()
          require('edgy.layout').update()
        end)
      end)
    end

    -- devdocs opens a PICKED doc into the CURRENT window (non-float). Relocate it
    -- to a fresh bottom split so the code window is left untouched, then mark it.
    -- pending_origin is captured by the keymaps before the picker runs. Marking is
    -- done only after the doc is in the bottom split, so edgy never tries to dock
    -- the code window itself.
    local pending_origin = nil
    local function dock_doc(docbuf)
      local origin = pending_origin
      pending_origin = nil
      -- No origin → this open was NOT a docked search (it's the <leader>o float, or
      -- a :Devdocs* command run directly). Leave the window exactly as devdocs made
      -- it; only the docked keymaps below relocate to the bottom.
      if not origin then
        return
      end
      if vim.api.nvim_win_is_valid(origin.win) then
        pcall(vim.api.nvim_win_set_buf, origin.win, origin.buf) -- restore code buffer
        pcall(vim.api.nvim_set_current_win, origin.win)
      end
      vim.cmd 'botright split | resize 15'
      pcall(vim.api.nvim_win_set_buf, 0, docbuf)
      mark_docked(docbuf)
    end

    require('nvim-devdocs').setup {
      wrap = true,
      -- No previewer_cmd: operations.lua renders through a previewer only when this
      -- is set (it pipes into a terminal channel and sets ft to the command name).
      -- Leaving it nil takes the `vim.bo[bufnr].ft = "markdown"` branch instead, so
      -- render-markdown.nvim styles the doc in a real buffer.
      -- previewer_cmd = 'glow',
      -- cmd_args = glow_args(),
      -- picker_cmd = false: the telescope preview shows RAW markdown (fast) instead
      -- of glow-rendering every focused entry. glow runs only on the opened doc
      -- (previewer_cmd above) and the <leader>sC grep result.
      picker_cmd = false,
      ensure_installed = { 'rust', 'go', 'javascript', 'node', 'typescript', 'react', 'python', 'html', 'c', 'cpp', 'gcc-14', 'gcc-14_cpp' },
      after_open = dock_doc,
    }

    -- Capture the origin window, then open the picker NORMALLY (no pre-split — that
    -- confused telescope's previewer teardown on a small UI, the E5108 error). The
    -- preview shows on the right, or below the results when the UI is narrow (see
    -- the flex layout in telescope.lua); the doc is moved to the bottom on select.
    local function open_docked(cmd)
      -- Only needed while glow was the renderer (cmd_args was read at render time,
      -- so it had to be refreshed to track editor resizes). Markdown reflows itself.
      -- pcall(function()
      --   require('nvim-devdocs.config').options.cmd_args = glow_args()
      -- end)
      pending_origin = { win = vim.api.nvim_get_current_win(), buf = vim.api.nvim_get_current_buf() }
      vim.cmd(cmd)
    end

    -- <leader>o: the CURRENT file's docs (cpp buffer → C++, .go → Go, …), DOCKED at
    -- the bottom like <leader>sD (DevdocsOpenCurrent is filetype-aware; open_docked
    -- relocates the result to the bottom edge).
    vim.keymap.set('n', '<leader>o', function()
      open_docked 'DevdocsOpenCurrent'
    end, { desc = 'DevDocs: current filetype (docked)' })
    vim.keymap.set('n', '<leader>sD', function()
      open_docked 'DevdocsOpen'
    end, { desc = '[S]earch [D]evDocs (docked)' })

    -- Content search: grep INSIDE the downloaded .md docs (ripgrep over the file
    -- bodies — NOT the entry titles), then dock the chosen file rendered through
    -- glow (same look as the panels above). The select action opens its own bottom
    -- split, so no relocate is needed here.
    vim.keymap.set('n', '<leader>sC', function()
      local actions = require 'telescope.actions'
      local action_state = require 'telescope.actions.state'
      require('telescope.builtin').live_grep {
        prompt_title = 'DevDocs content (grep)',
        search_dirs = { vim.fn.stdpath 'data' .. '/devdocs/docs' },
        additional_args = { '--max-filesize=1M' }, -- skip the few multi-MB doc blobs
        attach_mappings = function(prompt_bufnr)
          actions.select_default:replace(function()
            local entry = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            local path = entry and (entry.filename or entry.path)
            if not path then
              return
            end
            vim.cmd 'botright split | resize 15'
            -- PREVIOUS RENDERER (glow → ANSI in a terminal buffer). Kept for reference.
            -- vim.cmd 'enew'
            -- local cmd = { 'glow' }
            -- vim.list_extend(cmd, glow_args(0))
            -- table.insert(cmd, path)
            -- vim.fn.jobstart(cmd, { term = true })
            -- vim.bo.filetype = 'glow'
            -- vim.cmd 'stopinsert'
            -- The grep hit is already a Markdown file on disk, so open it directly:
            -- render-markdown styles it, and the buffer stays searchable and jumpable.
            vim.cmd('edit ' .. vim.fn.fnameescape(path))
            vim.bo.filetype = 'markdown'
            vim.wo.wrap = true
            vim.wo.conceallevel = 2
            mark_docked(vim.api.nvim_get_current_buf())
          end)
          return true
        end,
      }
    end, { desc = '[S]earch DevDocs [C]ontent (grep, docked)' })
  end,
}
