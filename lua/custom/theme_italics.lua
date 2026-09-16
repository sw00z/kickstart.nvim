-- One italic policy for every theme that opts in, so italic placement is decided
-- once instead of per-theme. Italic is a contrast tool, not wallpaper: nothing
-- high-density is eligible, and every group below is justified where it is listed.
--
-- The policy strips before it adds, and each theme's own italic switches are left
-- at their authored defaults. That is what makes `:ItalicPolicy off` honest: it
-- re-sources the scheme and you get the theme as its author wrote it, rather than
-- the theme minus its italics. Working at the highlight layer instead of the
-- config layer is also why toggling needs no plugin reload.
local M = {}

-- ~/.local/state/nvim/italic-policy.txt
local state_file = vim.fs.normalize(vim.fn.stdpath 'state' .. '/italic-policy.txt')

-- Each group is either a voice that is not the code, or a sparse single-token
-- marker. @string.documentation is separate from @comment because a Python
-- docstring is a string — without it, `#` comments go italic while `"""` doesn't.
-- @variable.parameter is captured only on the signature, so it costs one run per
-- parameter, not one per use.
--
-- Measured share of non-whitespace glyphs: ~19% on a 48-line class-heavy Python
-- module (all of it syntax markers, no comments) and ~25% on a comment-dense Lua
-- config file (all of it @comment). Comments dominate wherever they appear, so
-- the real dial is whether Comment belongs here at all — the syntax markers below
-- contribute 1-7% each.
--
-- @variable.builtin (self / this / cls) was measured and removed: at 3.8% of all
-- glyphs it fires on roughly every attribute access in Python, which fails the
-- sparseness test the rest of this list is chosen for.
--
-- Those shares predate the last four entries. @keyword.exception and
-- @keyword.directive are bounded by handler and include count, @label by grammars
-- that have labels at all, and @markup.emphasis is zero outside prose, so none of
-- them moves the code-file figure by a whole point.
local ADD = {
  'Comment',
  '@comment',
  '@comment.documentation',
  '@string.documentation',
  '@variable.parameter',
  '@keyword.return',
  '@keyword.coroutine', -- async / await / go — control flow that isn't linear
  '@keyword.exception', -- try / catch / raise — the other branch that isn't linear
  '@keyword.directive', -- #include / #define — preamble, not the code it precedes
  '@attribute', -- a decorator describes the line below it
  '@constant', -- UPPER_SNAKE across grammars; lowercase locals are @variable
  '@label', -- goto targets, loop labels, code-fence tags; single digits per file
  '@markup.emphasis', -- the one group where italic is the meaning, not a marker
}

-- The dense groups the six themes italicize by default: zenbones does all
-- strings, modus all keywords, vague has one global switch. Stripping here rather
-- than disabling their options keeps `off` mode authentic.
local STRIP = {
  'String',
  '@string',
  'Keyword',
  '@keyword',
  '@keyword.function',
  '@keyword.operator',
  '@keyword.conditional',
  '@keyword.repeat',
  '@keyword.import',
  'Statement',
  'Type',
  '@type',
  'Function',
  '@function',
  'Identifier',
  '@variable',
  'Boolean',
  '@boolean',
  'Todo',
}

-- Policy is on until explicitly turned off.
local function read_enabled()
  local fd = io.open(state_file, 'r')
  if not fd then
    return true
  end
  local value = fd:read '*l'
  fd:close()
  return value ~= 'off'
end

local function save_enabled(enabled)
  local fd = io.open(state_file, 'w')
  if fd then
    fd:write(enabled and 'on' or 'off')
    fd:close()
  end
end

M.enabled = read_enabled()

-- link = false resolves two things a plain get misses: a linked group (@comment →
-- Comment) and the treesitter capture fallback (@keyword.return → @keyword).
-- nvim_set_hl silently drops attributes on a definition that still carries a
-- `link` field, and `return` is captured as @keyword.return alone with no
-- @keyword extmark underneath, so italic-only would leave it at Normal fg.
local function resolve(group)
  return vim.api.nvim_get_hl(0, { name = group, link = false })
end

--- Re-apply the policy over whatever the active colorscheme just set.
function M.apply()
  if not M.enabled then
    return
  end

  for _, group in ipairs(STRIP) do
    local hl = resolve(group)
    -- Only write when there is something to remove — resolving replaces a link
    -- with a concrete definition, so an unconditional write would detach every
    -- group in the list from whatever the theme linked it to.
    if hl.italic then
      hl.italic = false
      if hl.cterm then
        hl.cterm.italic = false
      end
      vim.api.nvim_set_hl(0, group, hl)
    end
  end

  for _, group in ipairs(ADD) do
    local hl = resolve(group)
    if not vim.tbl_isempty(hl) then
      hl.italic = true
      -- The fallback that hands us a colour also hands us the parent's bold, so
      -- `return` arrives bold from every bold-keyword theme in this config.
      hl.bold = false
      -- nvim_set_hl mirrors gui → cterm only when cterm is absent.
      if hl.cterm then
        hl.cterm.italic = true
        hl.cterm.bold = false
      end
      vim.api.nvim_set_hl(0, group, hl)
    end
  end
end

--- Flip the policy and persist it. Re-sourcing the scheme is what restores the
--- theme's own italics when turning off — only the theme can put them back.
---@param enabled boolean
function M.set(enabled)
  M.enabled = enabled
  save_enabled(enabled)
  if vim.g.colors_name then
    pcall(vim.cmd.colorscheme, vim.g.colors_name)
  end
end

--- Run the policy after any of `patterns` is applied. Autocmds fire in
--- registration order and VeryLazy load order across specs is not guaranteed, so
--- a theme whose own autocmd rewrites a group in ADD must call M.apply() itself
--- as its last statement rather than relying on this firing later.
---@param patterns string[] ColorScheme autocmd patterns; globs allowed
function M.attach(patterns)
  vim.api.nvim_create_autocmd('ColorScheme', { pattern = patterns, callback = M.apply })

  vim.api.nvim_create_user_command('ItalicPolicy', function(input)
    local arg = input.args ~= '' and input.args or 'toggle'
    if arg == 'toggle' then
      M.set(not M.enabled)
    elseif arg == 'on' or arg == 'off' then
      M.set(arg == 'on')
    else
      vim.notify("ItalicPolicy: expected 'on', 'off' or 'toggle'", vim.log.levels.ERROR)
      return
    end
    vim.notify('Italic policy ' .. (M.enabled and 'on' or 'off (theme defaults)'))
  end, {
    nargs = '?',
    complete = function()
      return { 'on', 'off', 'toggle' }
    end,
    desc = 'Toggle the shared italic policy against theme defaults',
  })

  vim.keymap.set('n', '<leader>ui', function()
    M.set(not M.enabled)
  end, { desc = 'Toggle [I]talic policy' })
end

return M
