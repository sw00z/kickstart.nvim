-- Every noirbuddy palette this config defines, plus the vimdark-pastel overlay
-- that reuses Florals' diagnostics.
--
-- Three registers, not one. Quiet (Florals, Sorbet): every accent's luminance
-- sits inside a 9-12:1 band above body text at ~7.3:1, so hue is the only
-- variable separating an accent from bright grey and colour reads as punctuation
-- rather than emphasis. Mixed (Matcha, Dune, Thistle): accents bracket that band
-- instead of sitting inside it — 12.5-14.5:1 above every glyph grey, or 6.2-8.5:1
-- below it where saturation shows most, at up to 78% saturation. They stay pastel
-- by raising chroma at high lightness, never by darkening. Vivid (the retuned
-- stock noirbuddy): bound by neither, because #ff0088 at 5.00:1 is the ceiling
-- for a fully saturated magenta on #121212 and the theme is loud by design.
--
-- Shared by all three registers: noir_4 ~7.3:1 for Normal fg, noir_7 ~2.9:1 for
-- Comment, diagnostic_hint the least chromatic of the four diagnostics, and
-- diff_delete reusing the error hex. Recompute contrast before changing a hex.
local italics = require 'custom.theme_italics'

local M = {}

-- Ramp hue locked at 223-228 degrees, saturation 12-17%, so the cool cast peaks
-- in the midtones and vanishes at both ends — the greys read as paper, never as
-- tinted. noir_0 is brightest, noir_9 darkest.
-- stylua: ignore
M.florals = {
  background         = '#0E0F13',
  noir_0             = '#EDEFF5',
  noir_1             = '#DFE2EB',
  noir_2             = '#CBCFDA', -- 12.29:1  accent ceiling
  noir_3             = '#B3B8C6', --  9.67:1  accent floor
  noir_4             = '#9AA0B0', --  7.32:1  Normal fg (WCAG AAA)
  noir_5             = '#7F8695',
  noir_6             = '#666C7B',
  noir_7             = '#565D6D', --  2.90:1  Comment
  noir_8             = '#343945', -- Visual / Search / Pmenu bg
  noir_9             = '#1B1E26', -- CursorLine bg
  primary            = '#C9BFE4', -- lilac      10.99:1  literals and escape hatches
  secondary          = '#A8D5CE', -- mint       11.93:1  types
  diagnostic_error   = '#E8A0AC', -- rose        9.13:1
  diagnostic_warning = '#E8C79A', -- apricot    11.90:1  the only warm hue
  diagnostic_info    = '#A8C8E8', -- sky        11.03:1
  -- Deliberately the least chromatic of the four: hints are the most frequent and
  -- least urgent diagnostic, so the sign column stays quiet.
  diagnostic_hint    = '#C0C8D4', -- near-grey  11.37:1
  diff_add           = '#A9D9A2',
  diff_change        = '#9FBCD9', -- steel, not amber — warmth stays reserved for warning
  diff_delete        = '#E3A0AB',
}

-- Deeper black and a near-neutral ramp so the accents do all the colouring. The
-- luminance band is the same as Florals, so what separates the two palettes is
-- hue and saturation only: Sorbet is warmer and pinker at 41-76% HSL saturation
-- where Florals sits at 19-63%. Accent lightness stays at 71-82% to keep them
-- pastel — dropping lightness at fixed saturation turns a pastel vivid, so both
-- move together.
-- stylua: ignore
M.sorbet = {
  background         = '#08080B',
  noir_0             = '#F2F2F6',
  noir_1             = '#E0E0E6',
  noir_2             = '#CACAD2', -- 12.28:1  accent ceiling
  noir_3             = '#B2B2BC',
  noir_4             = '#9A9AA4', --  7.17:1  Normal fg
  noir_5             = '#82828C',
  noir_6             = '#66666F',
  noir_7             = '#5A5A64', --  2.93:1  Comment
  noir_8             = '#2C2C33',
  noir_9             = '#141418',
  primary            = '#EDB7C8', -- candy pink 11.63:1
  secondary          = '#97D4C1', -- mint       11.91:1
  diagnostic_error   = '#F3A8B6', -- watermelon 10.56:1
  diagnostic_warning = '#E5C596', -- apricot    12.15:1
  diagnostic_info    = '#A7C9EA', -- sky        11.61:1
  diagnostic_hint    = '#C6CAD6', -- near-grey  12.21:1
  diff_add           = '#A1D69C', --            12.01:1
  diff_change        = '#ABC4E7', --            11.22:1
  diff_delete        = '#F3A8B6', --            10.56:1
}

-- The stock `minimal` preset, retuned. Vivid by design, so each accent sits at the
-- highest saturation its hue allows at >=5:1 on #121212 and no two are within 25
-- degrees of each other. The background, the 0%-saturation ramp and the hot pink
-- are the theme's identity and are kept exactly; what changes is a grey secondary,
-- one hex shared by three roles, an error 19 degrees from primary, and a Comment
-- below the house 2.9:1.
-- stylua: ignore
M.noirbuddy = {
  background         = '#121212',
  noir_0             = '#FFFFFF',
  noir_1             = '#F5F5F5',
  noir_2             = '#D5D5D5', -- 12.76:1
  noir_3             = '#B4B4B4', --  9.04:1
  noir_4             = '#A7A7A7', --  7.79:1  Normal fg
  noir_5             = '#949494',
  noir_6             = '#737373',
  noir_7             = '#5E5E5E', --  2.89:1  Comment — stock #535353 is 2.44:1
  noir_8             = '#323232', -- Visual / Search / Pmenu bg
  noir_9             = '#212121', -- CursorLine bg
  primary            = '#FF0088', -- hot pink   5.00:1  the identity, unchanged
  -- noirbuddy's own cyan, promoted out of the diagnostic slot it shared with two
  -- other roles into the syntax slot #D5D5D5 held. It is the same luminance as the
  -- grey it replaces, so this adds chroma without adding brightness.
  secondary          = '#47EAE0', -- cyan      12.59:1
  -- Stock error is hue 347 against primary's 328; the 28-degree gap this buys is
  -- the fix, and the lift off 4.74:1 follows from it.
  diagnostic_error   = '#F2626C', -- red        6.01:1
  diagnostic_warning = '#FF7700', -- orange     7.04:1
  diagnostic_info    = '#4BB1FA', -- blue       8.00:1  clear of the cyan
  diagnostic_hint    = '#B6C5C4', -- cyan-grey 10.50:1
  diff_add           = '#00FF77', -- spring    13.89:1
  diff_change        = '#B08FDF', -- violet     6.99:1  the one hue noirbuddy lacked
  diff_delete        = '#F2626C', --            6.01:1  error hex
  keep_hue           = { 'strings', 'variables' },
}

-- Green where Florals is blue. Ramp hue locked at 142-148 degrees, 5-9%
-- saturation in the midtones — green reads tinted at saturations a blue cast
-- absorbs. Primary and warning sit above the glyph greys, everything else below.
-- stylua: ignore
M.matcha = {
  background         = '#0C110E',
  noir_0             = '#ECF1EE',
  noir_1             = '#DDE5E0',
  noir_2             = '#C9D2CD', -- 12.32:1
  noir_3             = '#B0BBB5', --  9.64:1
  noir_4             = '#96A39C', --  7.27:1  Normal fg (WCAG AAA)
  noir_5             = '#7C8982',
  noir_6             = '#646F69',
  noir_7             = '#546059', --  2.90:1  Comment
  noir_8             = '#333B36', -- Visual / Search / Pmenu bg
  noir_9             = '#1B201D', -- CursorLine bg
  primary            = '#B1E7AC', -- celadon    13.51:1  brighter than any glyph grey
  secondary          = '#A1A5E6', -- wisteria    8.20:1  below the grey zone
  diagnostic_error   = '#EA7C85', -- rose        7.00:1  72% sat, the loudest chroma here
  diagnostic_warning = '#ECCE92', -- honey      12.53:1
  diagnostic_info    = '#7BACDE', -- sky         7.98:1
  diagnostic_hint    = '#B2C5BA', -- green-grey 10.51:1
  diff_add           = '#8ADC87', --            11.49:1
  diff_change        = '#849FC4', -- steel       7.02:1  quiet: the most frequent diff state
  diff_delete        = '#EA7C85', --             7.00:1  error hex
  -- Strings are the largest literal glyph mass, so hueing them alone is the
  -- biggest chroma gain per group changed.
  keep_hue           = { 'strings' },
}

-- The one warm ramp: hue locked at 30-34 degrees, 6-10% saturation in the
-- midtones, so the greys read as unbleached paper. Primary pops by saturation
-- (78%) rather than brightness; warning is the brightest item, so gold is the
-- beacon. Info is cyan to stay clear of the harbor-blue secondary.
-- stylua: ignore
M.dune = {
  background         = '#110F0D',
  noir_0             = '#F2EFEC',
  noir_1             = '#E6E2DD',
  noir_2             = '#D3CEC9', -- 12.24:1
  noir_3             = '#BEB7B0', --  9.64:1
  noir_4             = '#A69F97', --  7.31:1  Normal fg (WCAG AAA)
  noir_5             = '#8C857D',
  noir_6             = '#716B64',
  noir_7             = '#635C54', --  2.90:1  Comment
  noir_8             = '#3D3833', -- Visual / Search / Pmenu bg
  noir_9             = '#211E1A', -- CursorLine bg
  primary            = '#EEA777', -- peach       9.50:1  78% sat; pops by chroma
  secondary          = '#89B0E2', -- harbor      8.54:1
  diagnostic_error   = '#ED6F75', -- rose        6.50:1  most saturated accent here
  diagnostic_warning = '#EFD790', -- gold       13.47:1  the brightest item
  diagnostic_info    = '#72C2D6', -- cyan        9.47:1
  diagnostic_hint    = '#C6BFB7', -- warm-grey  10.51:1
  diff_add           = '#8BD685', -- sage       10.98:1
  diff_change        = '#849EC3', -- steel       6.98:1  quiet
  diff_delete        = '#ED6F75', --             6.50:1  error hex
  -- Call sites become blue verbs against peach data; identifiers stay the quiet
  -- grey majority. Types share that blue, since noirbuddy paints Type with
  -- `secondary` too — peach is data, blue is everything that is not, grey is the
  -- rest.
  keep_hue           = { 'strings', 'functions' },
}

-- Violet ramp, gold literals — the only palette whose accents are warmer than its
-- ground. Ramp hue locked at 280-285 degrees, 7-11% saturation in the midtones.
-- stylua: ignore
M.thistle = {
  background         = '#110E12',
  noir_0             = '#F2EEF4',
  noir_1             = '#E6E0E9',
  noir_2             = '#D4CCD8', -- 12.26:1
  noir_3             = '#BFB5C3', --  9.69:1
  noir_4             = '#A79CAC', --  7.30:1  Normal fg (WCAG AAA)
  noir_5             = '#8D8292',
  noir_6             = '#736878',
  noir_7             = '#65596A', --  2.91:1  Comment
  noir_8             = '#3F3643', -- Visual / Search / Pmenu bg
  noir_9             = '#221C24', -- CursorLine bg
  primary            = '#F0E0A1', -- gold       14.50:1  brightest primary in the collection
  secondary          = '#78CCDD', -- ice        10.48:1
  diagnostic_error   = '#EA697A', -- rose        6.21:1  75% sat
  diagnostic_warning = '#EEC097', -- apricot    11.52:1  20 degrees off primary
  diagnostic_info    = '#91A6E5', -- periwinkle  8.02:1
  diagnostic_hint    = '#C6BCCB', -- violet-grey 10.46:1
  diff_add           = '#86D786', -- sage       11.03:1
  diff_change        = '#8D9ACE', -- periwinkle  6.98:1  quiet
  diff_delete        = '#EA697A', --             6.21:1  error hex
  -- The loudest of the three: most glyphs carry hue. Members and properties stay
  -- grey so chains keep a lightness hierarchy under coloured heads, and functions
  -- stay noir_0 so something is still the white majority.
  keep_hue           = { 'strings', 'variables' },
}

local PALETTES = {
  noirbuddy = M.noirbuddy,
  ['noirbuddy-florals'] = M.florals,
  ['noirbuddy-sorbet'] = M.sorbet,
  ['noirbuddy-matcha'] = M.matcha,
  ['noirbuddy-dune'] = M.dune,
  ['noirbuddy-thistle'] = M.thistle,
}

--- noirbuddy setup options for one of the custom variants.
--- styles are all off: the italic policy owns italics, and noirbuddy's own
--- styles.italic reaches only the four Diagnostic groups — three cues for one
--- message, on top of the sign and the lsp_lines text.
---@param name string
function M.noirbuddy_opts(name)
  return {
    colors = PALETTES[name],
    styles = { italic = false, bold = false, underline = false, undercurl = true },
  }
end

-- The four roles noirbuddy paints with an accent and this file otherwise flattens
-- to grey. `grey` is the quiet register, unchanged from how Florals and Sorbet
-- have always been drawn; `hue` is what the mixed register paints instead. A
-- palette opts a role out of flattening by naming it in `keep_hue`, so a palette
-- with no `keep_hue` is byte-for-byte what it was before the mixed register
-- existed. Which roles a palette keeps is a per-palette decision recorded next to
-- its table, not a global setting.
local ROLES = {
  -- Strings are 30-40% of a data-heavy file, so this is the single largest
  -- chroma decision in the whole scheme.
  strings = { groups = { '@string' }, grey = 'noir_2', hue = 'primary' },
  variables = { groups = { '@variable' }, grey = 'noir_2', hue = 'secondary' },
  -- Chains read as one unit when members sit a step under plain variables.
  members = { groups = { '@variable.member', '@property' }, grey = 'noir_3', hue = 'secondary' },
  -- Grey here marks call sites by lightness, which leaves hue free for data.
  functions = { groups = { 'Function', '@function' }, grey = 'noir_0', hue = 'secondary' },
}

--- Pull noirbuddy back toward black/white after its setup() has painted.
--- It gives every identifier `secondary` and every string `primary`; those two
--- assignments are the only thing standing between it and a monochrome theme.
--- The quiet palettes take both away. The mixed ones hand some of it back —
--- see ROLES above.
---@param name string
function M.refine(name)
  local p = PALETTES[name]
  local set = function(group, spec)
    vim.api.nvim_set_hl(0, group, spec)
  end

  local keeps = {}
  for _, role in ipairs(p.keep_hue or {}) do
    keeps[role] = true
  end
  for role, spec in pairs(ROLES) do
    local colour = p[keeps[role] and spec.hue or spec.grey]
    for _, group in ipairs(spec.groups) do
      set(group, { fg = colour })
    end
  end

  -- The accent moves off the string body and onto the escapes and interpolation
  -- braces inside it, where the information actually is, so `primary` means
  -- exactly "a literal value or an escape hatch". A palette that keeps `strings`
  -- hued gives the body that same accent, which collapses the distinction —
  -- deliberately, since there the string itself is already the coloured thing.
  for _, group in ipairs { '@string.escape', '@character.special', '@punctuation.special', '@number', '@number.float', '@boolean', 'Constant', 'PreProc' } do
    set(group, { fg = p.primary })
  end

  -- One pastel dot tracking the cursor, at zero density cost.
  set('CursorLineNr', { fg = p.primary, bold = true })

  -- The one place the theme is allowed to be loud, because you asked for it.
  set('Search', { fg = p.background, bg = p.secondary })
  set('IncSearch', { fg = p.background, bg = p.primary })

  -- @variable.parameter was just rewritten above via @variable, so the policy has
  -- to be re-asserted rather than left to fire later.
  italics.apply()
end

-- vimdark's own greys, kept as-is so the overlay stays recognisably vimdark.
local VIMDARK_GREY = {
  bright = '#E4E4E4',
  body = '#949494',
  scaffold = '#7C7C7C',
  dim = '#6C6C6C',
  border = '#4A4A4A',
}

-- Structure is expressed by lightness, meaning by hue. Four hue buckets is all
-- the eye needs on a black canvas; sage vs sand separates a string containing
-- digits from a numeric literal at a glance.
local VIMDARK_ACCENT = {
  literal = '#B9CBA4', -- sage  — what you read
  value = '#E0C8A0', -- sand  — what you compute with
  shape = '#A8C6D8', -- slate — vimdark's own #87afd7, lifted to pastel
  verb = '#D8B7C8', -- mauve — what is called
}

-- vimdark's treesitter section targets TSConstant / TSParameter / TSLabel, the
-- pre-0.10 names, which are inert on 0.11. Every @-capture below is therefore
-- required for the accents to reach a treesitter'd buffer at all.
local VIMDARK_GROUPS = {
  [VIMDARK_ACCENT.literal] = { 'String', '@string', '@markup.raw', '@markup.raw.block' },
  [VIMDARK_ACCENT.value] = { 'Number', 'Boolean', 'Constant', '@number', '@number.float', '@boolean', '@constant', '@constant.builtin' },
  [VIMDARK_ACCENT.shape] = { 'Type', '@type', '@type.builtin', '@constructor', '@module' },
  [VIMDARK_ACCENT.verb] = { 'Function', '@function', '@function.call', '@function.method', '@function.method.call', '@function.builtin' },
  -- Keywords are already positionally obvious, so they get the brightest value
  -- and no hue at all.
  [VIMDARK_GREY.bright] = {
    'Statement',
    'Keyword',
    'PreProc',
    '@keyword',
    '@keyword.function',
    '@keyword.operator',
    '@keyword.conditional',
    '@keyword.repeat',
    '@keyword.import',
    '@keyword.exception',
  },
  -- The majority of glyphs — this is what keeps the theme black and white.
  [VIMDARK_GREY.body] = { 'Identifier', '@variable', '@variable.member', '@property' },
  -- Single glyphs you need to see, not read.
  [VIMDARK_GREY.scaffold] = { '@operator', '@punctuation.bracket', '@punctuation.delimiter', '@markup.list' },
  [VIMDARK_GREY.dim] = { 'Comment', '@comment' },
}

--- Lay Florals accents over vimdark's greys. Plain vimdark stays authentic; this
--- runs only for the vimdark-pastel variant.
function M.vimdark()
  local p = M.florals
  local set = function(group, spec)
    vim.api.nvim_set_hl(0, group, spec)
  end

  for fg, groups in pairs(VIMDARK_GROUPS) do
    for _, group in ipairs(groups) do
      set(group, { fg = fg })
    end
  end

  -- vimdark defines none of these, and this config floats everything (edgy,
  -- telescope, neo-tree, lsp_lines), so without them the theme looks unfinished.
  set('FloatBorder', { fg = VIMDARK_GREY.border })
  set('WinSeparator', { link = 'VertSplit' })
  set('NormalNC', { link = 'Normal' }) -- vimade owns inactive dimming
  set('@markup.heading', { fg = VIMDARK_GREY.bright, bold = true })
  set('@markup.link.url', { fg = VIMDARK_ACCENT.shape, underline = true })

  local diagnostics = {
    Error = p.diagnostic_error,
    Warn = p.diagnostic_warning,
    Info = p.diagnostic_info,
    Hint = p.diagnostic_hint,
  }
  for level, fg in pairs(diagnostics) do
    set('Diagnostic' .. level, { fg = fg })
    -- No fg on the underline: lsp_lines already prints the message text.
    set('DiagnosticUnderline' .. level, { undercurl = true, sp = fg })
  end

  -- vimdark renders diffs as solid #87af87 / #af5f5f background blocks — the
  -- loudest thing in the theme, and a direct violation of the premise.
  set('DiffAdd', { fg = p.diff_add, bg = '#12180F' })
  set('DiffChange', { fg = p.diff_change, bg = '#0F1318' })
  set('DiffDelete', { fg = p.diff_delete, bg = '#180F12' })
  set('DiffText', { fg = p.diff_change, bg = '#16202B', bold = true })

  -- Comment was just rewritten, so re-assert the policy rather than leaving it to
  -- fire later.
  italics.apply()
end

return M
