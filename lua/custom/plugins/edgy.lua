-- edgy.nvim: a fixed, predictable window layout.
--
-- LEFT column (stacked top→bottom):
--   1. Files    neo-tree filesystem   (pinned, expanded)
--   2. Outline  aerial                (pinned, expanded — opens with the layout)
--   3. Git      neo-tree git_status   (pinned, collapsed bar)
--   4. Buffers  neo-tree buffers      (pinned, collapsed bar)
--
-- BOTTOM panel (full editor width, readable height):
--   Notes   snacks scratch notes      (not pinned — appears when a note opens,
--                                       gone when closed; see snacks.lua)
--
-- Prereqs `laststatus = 3` and `splitkeep = 'screen'` are set in lua/options.lua.
--
-- Matching: edgy assigns a window to a slot by `ft` + an optional `filter`.
-- neo-tree tags each source window with vim.b[buf].neo_tree_source, so three
-- ft='neo-tree' windows land in three different slots. The Notes panel matches
-- any markdown buffer whose file lives under the snacks scratch directory, which
-- docks every scratch note (new, picker-opened, or the default pad) while
-- leaving real markdown files (e.g. a README you edit) alone.

-- Snacks scratch files live here; the Notes panel docks markdown buffers from it.
local scratch_root = vim.fs.normalize(vim.fn.stdpath 'data' .. '/scratch')
local function is_scratch_note(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  return name ~= '' and vim.startswith(vim.fs.normalize(name), scratch_root)
end

-- True for a buffer devdocs deliberately opened to dock (marker set in its
-- after_open hook — see custom/plugins/devdocs.lua). Gates the DevDocs slots so
-- they capture picked docs only, NOT the telescope preview (also ft='glow').
local function is_devdocs_docked(buf)
  return vim.b[buf].devdocs_docked == true
end

-- True for a buffer open_docked() built for the Zeal panel (marker set in
-- custom/zeal/lua/telescope_zeal.lua). The buffer is a glow terminal (ft='glow'),
-- shared with the DevDocs slot, so the marker is what routes it to the Zeal slot.
local function is_zeal_docked(buf)
  return vim.b[buf].zeal_docked == true
end

-- A buffer that belongs on the bottom edge (Notes / DevDocs / Hover / Zeal / Run).
local function is_bottom_buf(buf)
  return is_scratch_note(buf) or is_devdocs_docked(buf) or vim.bo[buf].filetype == 'nvim-docs-view' or is_zeal_docked(buf) or vim.b[buf].run_output == true
end

-- Toggle the WHOLE bottom edge off/on while preserving what's open. edgy can't do
-- this natively for non-pinned content (its close destroys windows, its open only
-- revives pinned views), so track the docked BUFFERS: closing the windows on hide
-- (buffers survive), reopening each buffer into a bottom split on show (edgy
-- re-docks via the ft/marker). Mirrors what <leader>e does for the whole layout,
-- but scoped to the bottom and content-preserving.
local bottom_saved = nil
local function toggle_bottom()
  if bottom_saved then
    for _, buf in ipairs(bottom_saved) do
      if vim.api.nvim_buf_is_valid(buf) then
        vim.cmd 'botright split'
        pcall(vim.api.nvim_win_set_buf, 0, buf)
      end
    end
    bottom_saved = nil
    pcall(function()
      require('edgy.layout').update()
    end)
    pcall(function()
      require('edgy.editor').goto_main()
    end)
  else
    -- Collect bottom panels in VISUAL top-to-bottom order (win_screenpos row) so
    -- the restore rebuilds the same stack — nvim_list_wins() order is arbitrary.
    local entries = {}
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_config(win).relative == '' then -- skip floats
        local buf = vim.api.nvim_win_get_buf(win)
        if is_bottom_buf(buf) then
          local pos = vim.fn.win_screenpos(win)
          entries[#entries + 1] = { buf = buf, win = win, row = pos[1], col = pos[2] }
        end
      end
    end
    if #entries == 0 then
      return -- nothing docked to hide
    end
    table.sort(entries, function(a, b)
      return a.row < b.row or (a.row == b.row and a.col < b.col)
    end)
    bottom_saved = {}
    for _, e in ipairs(entries) do
      bottom_saved[#bottom_saved + 1] = e.buf
    end
    for _, e in ipairs(entries) do
      pcall(vim.api.nvim_win_close, e.win, true)
    end
  end
end

return {
  'folke/edgy.nvim',
  event = 'VeryLazy',
  keys = {
    -- Toggle the whole edgy layout (left column + bottom panel) from anywhere,
    -- including while editing a file — no need to focus an edgy window first.
    -- The file tree alone toggles with `\` (neo-tree), so <leader>e is reserved
    -- exclusively for the full edgy layout.
    {
      '<leader>e',
      function()
        require('edgy').toggle()
      end,
      desc = 'Toggle [e]dgy layout',
    },
    -- Toggle the whole bottom edge off/on, preserving the open panels (the
    -- companion to <leader>e for the full layout). Inside a panel, ]w/[w cycle the
    -- open windows and ]W/[W include collapsed ones; <c-q> collapses one to a bar.
    { '<leader>E', toggle_bottom, desc = 'Toggle bottom [E]dge (preserve panels)' },
  },
  opts = {
    animate = { enabled = false }, -- predictable, no slide-in; set true for the spinner
    -- Keep hidden windows alive. With the default (true), hiding the last visible
    -- panel on an edge closes the whole edgebar, destroying the hidden windows so
    -- <leader>E / ]W can't bring them back. false keeps <c-q>-hidden docs pickable.
    close_when_all_hidden = false,
    wo = {
      winbar = false, -- no dropbar breadcrumbs inside the narrow sidebars
    },
    left = {
      -- 1. File tree — the main, always-open section. Pinned so it's a
      -- permanent part of the column (not collapsed → shown expanded).
      {
        title = '󰉓 Files',
        ft = 'neo-tree',
        filter = function(buf)
          return vim.b[buf].neo_tree_source == 'filesystem'
        end,
        pinned = true,
        open = 'Neotree show filesystem position=left',
        size = { height = 0.35 },
      },
      -- 2. Symbol outline, directly under the file tree. Pinned + expanded.
      -- edgy runs `open = 'AerialOpen'` when the layout opens (<leader>e); aerial's
      -- attach_mode='global' then keeps the outline following the focused file.
      {
        title = '󰙅 Outline',
        ft = 'aerial',
        pinned = true,
        open = 'AerialOpen',
        size = { height = 0.25 },
      },
      -- 3. Git status.
      {
        title = '󰊢 Git',
        ft = 'neo-tree',
        filter = function(buf)
          return vim.b[buf].neo_tree_source == 'git_status'
        end,
        pinned = true,
        collapsed = true,
        open = 'Neotree show git_status position=left',
        size = { height = 0.2 },
      },
      -- 4. Open buffers.
      {
        title = '󰓩 Buffers',
        ft = 'neo-tree',
        filter = function(buf)
          return vim.b[buf].neo_tree_source == 'buffers'
        end,
        pinned = true,
        collapsed = true,
        open = 'Neotree show buffers position=left',
        size = { height = 0.2 },
      },
    },
    bottom = {
      -- Three on-demand panels share the bottom edge. None pinned: each appears
      -- when opened and closes with it. edgy only SPLITS the bottom among panels
      -- currently OPEN — a lone panel gets full height, so this isn't three cramped
      -- slivers. Switch between whatever's open with <leader>E (picker) or ]w / [w
      -- (cycle) from inside a panel; closing one returns the cursor where it was.
      --
      -- 1. Notes — scratch markdown docked from the snacks scratch dir (<leader>N…).
      {
        title = '󰎚 Notes',
        ft = 'markdown',
        filter = is_scratch_note,
        size = { height = 0.35 },
      },
      -- 2. DevDocs — every doc (picked via <leader>o / <leader>sD, or content-grep
      -- via <leader>sC) renders through glow into a terminal buffer (ft='glow').
      -- The marker filter is what keeps the telescope PREVIEW (also ft='glow') on
      -- the right instead of being yanked here. Multiple stack; switch with
      -- <leader>E or ]w/[w, hide with <c-q>.
      {
        title = '󰈙 DevDocs',
        -- ft = 'glow',  -- previous renderer; docs are now real Markdown buffers
        ft = 'markdown',
        filter = is_devdocs_docked,
        size = { height = 0.4 },
      },
      -- 3. Hover — nvim-docs-view's docked LSP documentation panel (<leader>Lk).
      -- Its buffer filetype is 'nvim-docs-view' (verified in the plugin source).
      {
        title = '󰋽 Hover',
        ft = 'nvim-docs-view',
        size = { height = 0.35 },
      },
      -- 4. Zeal — offline docset pages (<leader>sz). zeal-cli emits the entry's
      -- section as Markdown, glow renders it into a terminal buffer (ft='glow').
      -- ft='glow' is shared with the DevDocs slot, so the zeal_docked marker is what
      -- routes it here. See custom/zeal/lua/telescope_zeal.lua.
      {
        title = '󰗚 Zeal',
        -- ft = 'glow',  -- previous renderer; pages are now real Markdown buffers
        ft = 'markdown',
        filter = is_zeal_docked,
        size = { height = 0.4 },
      },
      -- 5. Run — program output from <leader>tr (lua/custom/run.lua). The runner
      -- executes the current file in a terminal buffer tagged ft='run-output';
      -- this slot docks it. Each run replaces the previous (the runner closes the
      -- old output first), so only the latest run shows — no stack of terminals.
      {
        title = '󰐊 Run',
        ft = 'run-output',
        size = { height = 0.35 },
      },
    },
  },
  -- No config function / auto-open: edgy starts CLOSED. Nothing docks on
  -- startup or when opening files. Open the whole layout on demand with
  -- <leader>e (toggle) — edgy then runs each pinned view's open command
  -- (Files→Neotree, Outline→AerialOpen, Git/Buffers→their commands). The bottom
  -- Notes panel opens independently via the <leader>N keymaps.
}
