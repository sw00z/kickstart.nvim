return {
  'folke/snacks.nvim',
  lazy = false,
  priority = 800, -- after colorscheme (1000) and ui.nvim (900)
  keys = {
    -- Git
    { '<leader>gB', function() Snacks.gitbrowse() end, desc = 'Open in GitHub' },
    { '<leader>gl', function() Snacks.lazygit() end, desc = 'Lazygit' },
    { '<leader>gf', function() Snacks.lazygit.log_file() end, desc = 'Lazygit file log' },
    -- GitHub issues/PRs
    { '<leader>gi', function() Snacks.gh.issues() end, desc = 'GitHub issues' },
    { '<leader>gp', function() Snacks.gh.prs() end, desc = 'GitHub PRs' },
    -- Scratch
    { '<leader>.',  function() Snacks.scratch() end, desc = 'Scratch buffer' },
    { '<leader>S',  function() Snacks.scratch.select() end, desc = 'Select scratch buffer' },
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

    -- Scratch buffers (quick Python/SQL pads)
    scratch = { enabled = true },

    -- LSP-aware file rename
    rename = { enabled = true },

    -- Smooth scroll (supplements mini.animate)
    scroll = { enabled = true },
  },
}
