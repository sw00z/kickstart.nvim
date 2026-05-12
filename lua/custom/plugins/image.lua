-- image.nvim — inline image rendering for molten cells, markdown, etc.
--
-- WSL2 caveat: image.nvim uses the kitty graphics protocol. Windows Terminal
-- does NOT pass that protocol through to nvim, so images silently fail.
-- Working terminals on WSL2: kitty (X11/Wayland over WSLg), wezterm, ghostty.
-- Inside Windows Terminal / VSCode terminal, molten will run and produce
-- text/Markdown output but image cells (matplotlib plots, etc.) won't render.
--
-- The opts function below picks a sensible backend from $TERM_PROGRAM and
-- falls back to disabling molten image output if no compatible terminal is
-- detected, so the user gets a clear text-only fallback instead of silent
-- failure.

return {
  '3rd/image.nvim',
  opts = function()
    local term = os.getenv 'TERM_PROGRAM' or ''
    local term_lower = term:lower()
    -- Kitty graphics protocol: kitty, wezterm, ghostty all advertise via TERM_PROGRAM
    local kitty_compatible = term_lower:match 'kitty' or term_lower:match 'wezterm' or term_lower:match 'ghostty'

    if not kitty_compatible then
      -- Tell molten not to render images — text-only cell output stays usable.
      vim.g.molten_image_provider = 'none'
    end

    return {
      backend = 'kitty',
      integrations = {},
      max_width = 100,
      max_height = 12,
      max_height_window_percentage = math.huge,
      max_width_window_percentage = math.huge,
      window_overlap_clear_enabled = true,
      window_overlap_clear_ft_ignore = { 'cmp_menu', 'cmp_docs', '' },
    }
  end,
}
