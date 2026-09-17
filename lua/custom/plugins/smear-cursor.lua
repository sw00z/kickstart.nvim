-- Cursor trail animation. WezTerm has no equivalent of Rio's effects.trail-cursor
-- or Kitty's cursor_trail (wezterm/wezterm#7067, #7387 are both still open), and
-- snacks only covers smooth scrolling via Snacks.scroll -- not cursor motion. This
-- draws the smear with ordinary text cells instead, so it is terminal-agnostic and
-- needs no graphics protocol.
return {
  'sphamba/smear-cursor.nvim',
  event = 'VeryLazy',
  opts = {
    -- CaskaydiaCove is Cascadia Code patched, and Cascadia is the font the plugin
    -- names as carrying legacy computing symbols. Those sub-cell block glyphs are
    -- what let the smear render at finer than one cell, so the trail reads as a
    -- tapering streak rather than a row of lit cells.
    legacy_computing_symbols_support = true,

    -- The two motions worth animating. Neighbour-line movement is most of normal
    -- editing, and buffer switches are where the cursor jumps far enough that
    -- losing track of it is the actual problem being solved.
    smear_between_neighbor_lines = true,
    smear_between_buffers = true,

    -- Animate in buffer coordinates while scrolling, so the smear tracks the text
    -- it started from instead of sliding against a moving viewport.
    scroll_buffer_space = true,

    -- Insert mode stays un-smeared: the cursor is already where the eye is during
    -- typing, so the trail is noise there rather than a cue.
    smear_insert_mode = false,
  },
}
