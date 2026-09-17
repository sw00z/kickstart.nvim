-- Run the current file as a program and dock its stdout/stderr in the edgy
-- BOTTOM panel (the "Run" slot in custom/plugins/edgy.lua), without leaving
-- Neovim. This complements neotest: neotest runs *tests* (discovery +
-- `go test`/`pytest`/…); this runs the file itself (`go run`, `python3`, …).
--
-- Docking mechanism: the command runs in a terminal buffer tagged with
-- ft='run-output' and b:run_output=true. edgy matches that ft to its Run slot
-- and absorbs the bottom split into the bottom edgebar (same approach as the
-- glow-backed DevDocs/Zeal panels). Each run closes the previous output first,
-- so the panel always shows only the latest run.
local M = {}

-- True if `name` exists at or above `dir` — i.e. the file is inside a project of
-- that kind (Cargo crate, etc.). Used to pick project builds over single-file.
local function project_has(dir, name)
  return vim.fs.find(name, { upward = true, path = dir, type = 'file' })[1] ~= nil
end

-- The C/C++ standard clangd uses for files under `dir`, so a run matches what
-- the LSP analyzed instead of drifting from it. An approximation of clangd's
-- own resolution, not an emulation: it reads a plain `-std=` out of the nearest
-- config and ignores `If:` conditions, `Remove:`, and compile databases. That
-- is sufficient because only loose files reach here — anything with a real
-- build system should be run through projector (<leader>j) instead.
-- `fallback` doubles as the language selector, so a config shared by a mixed
-- tree can't hand a C++ standard to a C build or the reverse.
local function config_std(dir, fallback)
  local want_cxx = fallback:find '%+%+' ~= nil
  -- Every ancestor `.clangd` applies, innermost winning; vim.fs.find returns
  -- them nearest-first, so the first one carrying an -std is the effective one.
  -- A `compile_flags.txt` only supplies the base command, so it loses to any
  -- `.clangd` -std while still beating the default.
  -- `stop` is exclusive, so stopping at the parent of $HOME keeps ~/.clangd —
  -- the natural place for a machine-wide default — inside the search.
  local home = vim.uv.os_homedir()
  local opts = { upward = true, path = dir, type = 'file', stop = home and vim.fs.dirname(home) or nil }
  local configs = vim.fs.find('.clangd', vim.tbl_extend('force', opts, { limit = math.huge }))
  vim.list_extend(configs, vim.fs.find('compile_flags.txt', opts))
  for _, cfg in ipairs(configs) do
    local ok, lines = pcall(vim.fn.readfile, cfg)
    if ok then
      local std
      for _, line in ipairs(lines) do
        if not line:match '^%s*#' then -- a YAML comment mentioning -std= is not a flag
          for found in line:gmatch '%-std=([%w%+%.%-]+)' do
            if (found:find '%+%+' ~= nil) == want_cxx then
              std = found -- last matching -std wins, as on a real command line
            end
          end
        end
      end
      if std then
        return std
      end
    end
  end
  return fallback
end

-- filetype -> command. A value is either a string template or a
-- function(ctx) -> string template, where ctx.has(name) reports project files
-- above the current file and ctx.dir is the file's directory. Placeholders are
-- substituted afterward:
--   {file} absolute path · {stem} path minus extension · {dir} containing dir ·
--   {out} unique temp binary (compiled output; never written into the project).
-- The runner lcd's into {dir} first, so bare globs/`.`/cargo resolve correctly.
-- Compile-then-run forms chain with `&&` so a failed build shows its error and
-- never runs a stale binary.
local commands = {
  python = 'python3 {file}',
  -- `go run .` builds the whole package in {dir}, so a multi-file package
  -- (main.go + deck.go) runs without naming every file.
  go = 'go run .',
  javascript = 'node {file}',
  typescript = 'npx tsx {file}',
  javascriptreact = 'node {file}',
  typescriptreact = 'npx tsx {file}',
  lua = 'lua {file}',
  sh = 'bash {file}',
  bash = 'bash {file}',
  zig = 'zig run {file}',
  -- Cargo crate → build & run the whole crate (cargo finds Cargo.toml upward);
  -- otherwise a loose single file → rustc.
  rust = function(ctx)
    if ctx.has 'Cargo.toml' then
      return 'cargo run'
    end
    return 'rustc {file} -o {out} && {out}'
  end,
  -- C/C++: compile every sibling source in {dir} together — the analog of
  -- `go run .` — so a multi-file program (main.c + deck.c) builds without naming
  -- each file. Assumes one program per directory; for real multi-target builds
  -- use the projector job runner (<leader>j) with a .vim/projector.json.
  -- The standard comes from the same `.clangd` the LSP reads, so changing it in
  -- one place moves both. The fallbacks apply only when no config exists above
  -- the file: gnu23 is gcc-15's own C default, so C runs are unaffected; c++26
  -- is the newest g++ 15 accepts.
  c = function(ctx)
    return ('cc -std=%s *.c -o {out} && {out}'):format(config_std(ctx.dir, 'gnu23'))
  end,
  cpp = function(ctx)
    return ('c++ -std=%s *.cpp -o {out} && {out}'):format(config_std(ctx.dir, 'c++26'))
  end,
}

-- Close any prior run-output window and wipe its buffer (terminating the job),
-- so a re-run replaces the panel instead of stacking a second terminal.
local function close_previous()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.b[buf].run_output then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.b[buf].run_output then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end
end

function M.run_file()
  local ft = vim.bo.filetype
  local entry = commands[ft]
  if not entry then
    vim.notify('No run command for filetype: ' .. (ft == '' and '(none)' or ft), vim.log.levels.WARN, { title = 'Run file' })
    return
  end

  local file = vim.fn.expand '%:p'
  if file == '' then
    vim.notify('Buffer has no file on disk — save it first', vim.log.levels.WARN, { title = 'Run file' })
    return
  end
  vim.cmd 'silent! write' -- persist edits before running

  local dir = vim.fn.fnamemodify(file, ':h')

  -- Resolve function commands against the project context, then substitute
  -- placeholders. Function-form gsub avoids `%` being treated as a replacement
  -- special when a shellescaped path contains one.
  local template = type(entry) == 'function' and entry {
    dir = dir,
    has = function(name)
      return project_has(dir, name)
    end,
  } or entry
  local repls = {
    file = vim.fn.shellescape(file),
    stem = vim.fn.shellescape(vim.fn.fnamemodify(file, ':r')),
    dir = vim.fn.shellescape(dir),
    out = vim.fn.shellescape(vim.fn.tempname()),
  }
  local cmd = (template:gsub('{(%w+)}', function(key)
    return repls[key]
  end))

  close_previous()

  -- Open a full-width split at the bottom and run the command in a terminal
  -- there. lcd scopes the terminal's cwd to the file's directory. Tagging the
  -- buffer (ft + marker) is what routes it into edgy's Run slot.
  local editor_win = vim.api.nvim_get_current_win()
  vim.cmd 'botright split'
  vim.cmd('lcd ' .. vim.fn.fnameescape(dir))
  vim.cmd('terminal ' .. cmd)
  local buf = vim.api.nvim_get_current_buf()
  vim.b[buf].run_output = true
  vim.bo[buf].filetype = 'run-output'

  -- Let edgy dock the panel, then return focus to the editor so the edit→run→
  -- read→edit loop stays one keystroke. Output stays visible (and auto-scrolls).
  pcall(function()
    require('edgy.layout').update()
  end)
  if vim.api.nvim_win_is_valid(editor_win) then
    vim.api.nvim_set_current_win(editor_win)
  end
end

return M
