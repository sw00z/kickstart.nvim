-- ── Notes (snacks-backed, docked in the edgy BOTTOM panel) ───────────────────
-- Notes are markdown snacks-scratch files under stdpath('data')/scratch. The
-- scratch window opens at the bottom (scratch.win.position below), and edgy's
-- bottom Notes slot docks any markdown buffer from that directory — so the
-- panel is full-width and readable instead of a left-sidebar sliver.
--   <leader>Nf  search/open project notes (picker: <CR> open · <c-n> new · <c-x> delete)
--   <leader>Ns  new note
--   <leader>Nn  open the default persistent notes pad
--   <leader>Nt  toggle the notes panel into/out of view
-- Opening any note reuses the single bottom panel — notes never stack on top of
-- one another (see notes_show below).
-- :NotesClear (command only, no keybind) wipes the default pad.
local scratch_root = vim.fs.normalize(vim.fn.stdpath 'data' .. '/scratch')
local notes_file = vim.fs.normalize(scratch_root .. '/notes.md')

-- True when `buf` is one of our scratch notes (mirrors the edgy bottom filter).
local function is_scratch_note(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  return name ~= '' and vim.startswith(vim.fs.normalize(name), scratch_root)
end

-- Close every docked note window except `keep` (a bufnr, or nil to close all).
local function close_note_wins(keep)
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    local b = vim.api.nvim_win_get_buf(w)
    if is_scratch_note(b) and b ~= keep then
      pcall(vim.api.nvim_win_close, w, false)
    end
  end
end

-- Show a note in the SINGLE bottom Notes panel. Snacks.scratch.open opens a new
-- split for any buffer not already on screen, and edgy docks every matching
-- markdown window into the bottom edgebar — so opening a second note would stack
-- a new panel on the first. To keep one reusable panel: if the note is already
-- open, focus it (and drop any other note windows); otherwise close existing
-- note windows first, then open. Closing + reopening (vs. swapping the buffer in
-- place) keeps snacks' autowrite-on-hide autocmd armed.
--   `scratch` is a snacks.scratch.File (from the picker) or a Config (pad/new).
local function notes_show(scratch)
  if scratch.file then
    local buf = vim.fn.bufadd(vim.fs.normalize(scratch.file))
    local win = vim.fn.bufwinid(buf)
    if win ~= -1 then
      close_note_wins(buf)
      vim.api.nvim_set_current_win(win)
      return
    end
  end
  close_note_wins(nil)
  Snacks.scratch.open(scratch)
end

-- Open the default persistent notes pad in the single bottom panel.
local function notes_open()
  notes_show { file = notes_file, name = 'Notes', ft = 'markdown' }
end

-- Toggle the notes panel: close any open note window, or open the pad.
local function notes_toggle()
  local closed = false
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if is_scratch_note(vim.api.nvim_win_get_buf(w)) then
      pcall(vim.api.nvim_win_close, w, false)
      closed = true
    end
  end
  if not closed then
    notes_open()
  end
end

-- Reset the default pad. Exposed as :NotesClear only (no keybind) so a full
-- wipe is always deliberate.
local function notes_clear()
  local buf = vim.fn.bufadd(notes_file)
  vim.fn.bufload(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { '# Notes', '' })
  vim.api.nvim_buf_call(buf, function()
    vim.cmd 'silent write'
  end)
  vim.notify('Notes cleared', vim.log.levels.INFO, { title = 'Notes' })
end

return {
  'folke/snacks.nvim',
  lazy = false,
  priority = 800, -- after colorscheme (1000) and ui.nvim (900)
  keys = {
    -- Git
    {
      '<leader>gB',
      function()
        Snacks.gitbrowse()
      end,
      desc = 'Open in GitHub',
    },
    {
      '<leader>gl',
      function()
        Snacks.lazygit()
      end,
      desc = 'Lazygit',
    },
    {
      '<leader>gf',
      function()
        Snacks.lazygit.log_file()
      end,
      desc = 'Lazygit file log',
    },
    -- GitHub issues/PRs. The snacks.gh module exposes singular method names
    -- (`.issue` / `.pr`), not plurals. `<leader>gP` (capital) is used for PRs
    -- because gitsigns claims lowercase `<leader>gp` buffer-locally for
    -- "preview hunk" inside git-tracked files (gitsigns.lua:67).
    {
      '<leader>gi',
      function()
        Snacks.gh.issue()
      end,
      desc = 'GitHub issues',
    },
    {
      '<leader>gP',
      function()
        Snacks.gh.pr()
      end,
      desc = 'GitHub PRs',
    },
    -- Notes (unified <leader>N namespace; docked in the bottom panel — see helpers above)
    -- The picker reuses the single bottom panel via notes_show (default scratch_open
    -- would open a second split). Deletion is the source's built-in <c-x> (the
    -- <c-n> = new and <c-x> = delete input keys come from the scratch source).
    {
      '<leader>Nf',
      function()
        Snacks.picker.scratch {
          confirm = function(picker, item)
            picker:close()
            if item then
              notes_show(item.item)
            end
          end,
        }
      end,
      desc = 'Search/open notes',
    },
    {
      '<leader>Ns',
      function()
        notes_show { ft = 'markdown' }
      end,
      desc = 'New note',
    },
    { '<leader>Nn', notes_open, desc = 'Open [N]otes pad' },
    { '<leader>Nt', notes_toggle, desc = 'Toggle notes panel' },
    -- Note SEARCH: <leader>Nf (above) matches note titles; these search bodies.
    -- Grep "things I've written down" (full-text) + a recency list, scoped to the
    -- scratch dir, reusing the snacks picker already in play.
    {
      '<leader>NG',
      function()
        Snacks.picker.grep { dirs = { scratch_root } }
      end,
      desc = '[N]otes [G]rep (body)',
    },
    {
      '<leader>Nr',
      function()
        Snacks.picker.files { dirs = { scratch_root } }
      end,
      desc = '[N]otes [R]ecent',
    },
    -- Man pages — reuses the snacks picker (apropos under the hood, opens :Man).
    {
      '<leader>sM',
      function()
        Snacks.picker.man()
      end,
      desc = '[S]earch [M]an pages',
    },
    -- Notifications handled by nvim-notify (see notify.lua)
  },
  opts = {
    -- Large file handling (auto-disables treesitter/LSP on big files)
    bigfile = { enabled = true },

    -- Dashboard (replaces dashboard-nvim)
    dashboard = {
      enabled = true,
      sections = {
        { section = 'header' },
        {
          pane = 2,
          section = 'terminal',
          cmd = vim.fn.stdpath 'config' .. '/color-scripts/pipes2-slim',
          height = 5,
          padding = 1,
          ttl = 0, -- keep alive (animated)
        },
        { section = 'keys', gap = 1, padding = 1 },
        {
          pane = 2,
          icon = ' ',
          desc = 'Browse Repo',
          padding = 1,
          key = 'b',
          action = function()
            Snacks.lazygit()
          end,
        },
        { pane = 2, icon = ' ', title = 'Projects', section = 'projects', indent = 2, padding = 1 },
        function()
          local in_git = Snacks.git.get_root() ~= nil
          local cmds = {
            {
              title = 'Recent Commits',
              cmd = 'git log --oneline -5 2>/dev/null || echo "No commits"',
              key = 'C',
              action = function()
                Snacks.lazygit.log()
              end,
              icon = ' ',
              height = 5,
            },
            {
              title = 'Open Issues',
              cmd = 'gh issue list -L 3 2>/dev/null || echo "No issues"',
              key = 'I',
              action = function()
                Snacks.gh.issue()
              end,
              icon = ' ',
              height = 3,
            },
            {
              icon = ' ',
              title = 'Open PRs',
              cmd = 'gh pr list -L 3 2>/dev/null || echo "No PRs"',
              key = 'p',
              action = function()
                Snacks.gh.pr()
              end,
              height = 3,
            },
            {
              icon = ' ',
              title = 'Git Status',
              cmd = 'git --no-pager diff --stat -B -M -C 2>/dev/null || echo "Working tree clean"',
              height = 5,
            },
          }
          return vim.tbl_map(function(cmd)
            return vim.tbl_extend('force', {
              pane = 2,
              section = 'terminal',
              enabled = in_git,
              padding = 0,
              ttl = 5 * 60,
              indent = 3,
            }, cmd)
          end, cmds)
        end,
        { section = 'startup' },
      },
    },

    -- Indent guides (replaces indent-blankline)
    indent = {
      enabled = true,
      animate = { enabled = true },
    },

    -- Notifications handled by nvim-notify (see notify.lua)
    notifier = { enabled = false },

    -- Toggle helpers (consistent toggle patterns)
    toggle = { enabled = true },

    -- Open file/line on GitHub
    gitbrowse = { enabled = true },

    -- Floating lazygit
    lazygit = { enabled = true },

    -- GitHub issues and PRs
    gh = { enabled = true },

    -- Scratch buffers, used as project notes. snacks defaults a scratch to a
    -- FLOAT, which edgy can't manage; position='bottom' makes it a split so
    -- edgy's bottom Notes slot can dock it. Height is owned by edgy (the slot's
    -- size), not set here. Every open path (new / picker / pad) inherits this.
    scratch = {
      enabled = true,
      win = { position = 'bottom' },
    },

    -- LSP-aware file rename
    rename = { enabled = true },

    -- Smooth scroll (supplements mini.animate)
    scroll = { enabled = true },
  },
  config = function(_, opts)
    require('snacks').setup(opts)
    -- Commands back the docked notes pad. :Notes is the stable handle edgy's
    -- Notes slot opens (a slot `open` can't require a local in this module).
    vim.api.nvim_create_user_command('Notes', notes_open, { desc = 'Open the docked notes pad' })
    vim.api.nvim_create_user_command('NotesClear', notes_clear, { desc = 'Wipe the entire notes pad' })
  end,
}
