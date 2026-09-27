-- nvim-fFHighlight: f/F highlight every match of the target char on the line and number
-- repeats past the threshold. It sets the charsearch, so native ; and , repeat the jump.
-- flash.nvim's char mode also maps f/F and is disabled in flash.lua.

-- setup() defines its groups once with `hi default`; :colorscheme clears them, so reapply.
local function hint_highlights()
  local warn = vim.api.nvim_get_hl(0, { name = 'DiagnosticWarn', link = false }).fg
  local set = vim.api.nvim_set_hl
  set(0, 'fFHintChar', { fg = warn, bold = true })
  set(0, 'fFHintNumber', { fg = warn, bold = true })
  set(0, 'fFHintWords', { underline = true })
  set(0, 'fFHintCurrentWord', { link = 'fFHintWords' })
  set(0, 'fFPromptSign', { fg = warn, bold = true })
end

return {
  'kevinhwang91/nvim-fFHighlight',
  -- stylua: ignore
  keys = {
    { 'f', function() require('fFHighlight').findChar() end, mode = { 'n', 'x' }, desc = 'Find char forward' },
    { 'F', function() require('fFHighlight').findChar(true) end, mode = { 'n', 'x' }, desc = 'Find char backward' },
  },
  config = function()
    -- lazy owns the f/F mappings above; the plugin's own would duplicate them.
    require('fFHighlight').setup { disable_keymap = true }
    hint_highlights()
    vim.api.nvim_create_autocmd('ColorScheme', { callback = hint_highlights })
  end,
}
