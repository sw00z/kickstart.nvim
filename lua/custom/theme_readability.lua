-- One readability floor for the whole colorscheme collection, measured rather
-- than declared. Two failures this repairs, both of which reach you through `K`:
--
-- 1. render-markdown links its *surfaces* to the theme's *signal* groups
--    (render-markdown/core/colors.lua): the code band to ColorColumn, the six
--    heading bands to DiffText / DiffAdd / DiffChange / DiffDelete / Visual /
--    CursorColumn. Those are authored to grab attention — a diff marker, the
--    selection, the 80-column ruler — not to be read against. An LSP hover
--    arrives as a fenced code block, so on a theme whose ColorColumn is a signal
--    colour the whole float body is painted with it and the code inside keeps
--    foregrounds chosen for a different background. Across the 159 pickable
--    names the bands run as far out as elflord's pure red #CD0000, which sits
--    3.60:1 off its own background.
--
-- 2. render-markdown sets those links once, from its plugin/ file, with
--    default = true. `:colorscheme` runs `hi clear`, which drops default links,
--    and its own ColorScheme handler only rebuilds derived groups. So the bands
--    are live on a fresh start and gone after the first <leader>sc switch. This
--    module runs after `hi clear` and writes the groups concretely, so the two
--    states become one.
--
-- The rule: a theme's syntax colours are readable against that theme's own
-- Normal bg, so any band that is a small perturbation of Normal bg is safe by
-- construction, and a band that is not was never a surface. Bands within the
-- threshold are written back unchanged — a theme that already does the right
-- thing looks identical before and after.
local M = {}

-- Contrast of band against Normal bg, above which the band is a signal colour.
-- Tuned against the measured distribution over all 159 names: the well-behaved
-- bands cluster at or below 1.75 and the broken ones run from 1.81 to 7.82.
local BAND_MAX = 1.8

-- Absolute floor for code text sitting on the band. Any band costs the darkest
-- token some contrast — that is what a band is — so this is set well under the
-- 3:1 marginal zone and catches only bands that push a token to genuinely
-- unreadable, not the ordinary cost. It exists for the themes whose own
-- ColorColumn is subtle enough to pass BAND_MAX while still burying one capture
-- — gruber-darker's @property lands at 1.64:1 on its #453D41.
local FG_MIN = 2.0

-- The captures a type signature is actually built from, which is what has to
-- stay readable on the code band.
local CODE_FG = {
  '@variable',
  '@function',
  '@type',
  '@keyword',
  '@string',
  '@number',
  '@property',
  '@variable.member',
  '@operator',
  'Constant',
  'Identifier',
}

--- What has to stay readable on the band behind a heading of this level.
--- Normal is in the list because a theme that leaves the capture unset renders
--- the heading in the base foreground, and that is then what lands on the band.
local function heading_fg(level)
  return { ('@markup.heading.%d.markdown'):format(level), 'Normal' }
end

-- How far a derived band moves from Normal bg toward Normal fg. Direction is
-- whatever the theme's own contrast direction is, so this darkens on a light
-- theme and lightens on a dark one with no `background` check.
local LIFT = 0.08

-- render-markdown's default link targets, which `hi clear` has already dropped
-- by the time this runs. Kept in sync with its core/colors.lua by hand; a
-- version that renames these leaves the band at Normal bg rather than misplacing
-- it, so drift degrades quietly.
local BANDS = {
  { group = 'RenderMarkdownCode', source = 'ColorColumn', fill = true, fg = CODE_FG },
  { group = 'RenderMarkdownH1Bg', source = 'DiffText', fg = heading_fg(1) },
  { group = 'RenderMarkdownH2Bg', source = 'DiffAdd', fg = heading_fg(2) },
  { group = 'RenderMarkdownH3Bg', source = 'DiffChange', fg = heading_fg(3) },
  { group = 'RenderMarkdownH4Bg', source = 'DiffDelete', fg = heading_fg(4) },
  { group = 'RenderMarkdownH5Bg', source = 'Visual', fg = heading_fg(5) },
  { group = 'RenderMarkdownH6Bg', source = 'CursorColumn', fg = heading_fg(6) },
}

local function split(rgb)
  return math.floor(rgb / 0x10000) % 0x100, math.floor(rgb / 0x100) % 0x100, rgb % 0x100
end

local function join(r, g, b)
  return math.floor(r + 0.5) * 0x10000 + math.floor(g + 0.5) * 0x100 + math.floor(b + 0.5)
end

local function channel(c)
  c = c / 255
  return c <= 0.04045 and c / 12.92 or ((c + 0.055) / 1.055) ^ 2.4
end

local function luminance(rgb)
  local r, g, b = split(rgb)
  return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
end

--- WCAG 2.x contrast ratio, 1:1 to 21:1.
local function contrast(a, b)
  local hi, lo = luminance(a), luminance(b)
  if hi < lo then
    hi, lo = lo, hi
  end
  return (hi + 0.05) / (lo + 0.05)
end

local function blend(from, to, t)
  local fr, fg, fb = split(from)
  local tr, tg, tb = split(to)
  return join(fr + (tr - fr) * t, fg + (tg - fg) * t, fb + (tb - fb) * t)
end

-- link = false collapses both a link and the treesitter capture fallback into a
-- concrete definition, for the same reason theme_italics.lua resolves this way.
local function resolve(group)
  return vim.api.nvim_get_hl(0, { name = group, link = false })
end

-- What this module last wrote, so a later run reads the theme's own value and
-- never its own. Not every colorscheme runs `hi clear` — plain noirbuddy applies
-- through colorbuddy's setup() and does not — so without this the previous
-- scheme's band is still standing and gets adopted as if the new theme had
-- chosen it.
local written = {}

local function set(group, spec)
  vim.api.nvim_set_hl(0, group, spec)
  written[group] = spec.bg
end

--- Does every foreground this band carries clear FG_MIN against it?
local function legible(bg, groups)
  for _, group in ipairs(groups) do
    local fg = resolve(group).fg
    if fg and contrast(fg, bg) < FG_MIN then
      return false
    end
  end
  return true
end

--- The band this theme actually asked for, ignoring anything we left behind.
local function claimed(group, source)
  local current = resolve(group).bg
  if current == written[group] then
    current = nil
  end
  return current or resolve(source).bg
end

--- Measure the active theme without changing it. `asked` is what the theme
--- requested through its own group or render-markdown's link target; `live` is
--- what is painting now, which differs exactly where a band was repaired.
---@return table[] rows, table normal
function M.measure()
  local normal = resolve 'Normal'
  local rows = {}
  for _, band in ipairs(BANDS) do
    local asked = claimed(band.group, band.source)
    rows[#rows + 1] = {
      group = band.group:gsub('^RenderMarkdown', ''),
      source = band.source,
      asked = asked,
      live = resolve(band.group).bg,
      ratio = (asked and normal.bg) and contrast(asked, normal.bg) or nil,
      readable = asked and legible(asked, band.fg) or nil,
    }
  end
  return rows, normal
end

--- Re-derive the documentation surfaces over whatever the colorscheme just set.
function M.apply()
  local normal = resolve 'Normal'
  local float = resolve 'NormalFloat'

  -- A fully transparent theme (mellow, nordic, oxocarbon, flow) leaves Normal
  -- with no bg at all, so borrow the nearest opaque surface it does define
  -- before giving up.
  local surface = float.bg or normal.bg or resolve('Pmenu').bg or resolve('CursorLine').bg

  -- LSP floats are routed here from lspconfig.lua. Every noirbuddy variant and
  -- the four transparent themes leave NormalFloat with no bg, which makes a
  -- hover composite over the buffer text underneath it.
  if surface then
    local border = resolve 'FloatBorder'
    set('LspFloatNormal', { fg = float.fg or normal.fg, bg = surface })
    set('LspFloatBorder', { fg = border.fg or normal.fg, bg = surface })
  end

  if not normal.bg then
    return
  end

  -- No fg to move toward means no way to derive a band; the theme keeps its own.
  local derived = normal.fg and blend(normal.bg, normal.fg, LIFT) or nil

  for _, band in ipairs(BANDS) do
    -- Two ways to fail: the band is a signal colour rather than a surface, or
    -- it is subtle enough but still buries one of the theme's own captures.
    local bg = claimed(band.group, band.source)
    local sound = bg and contrast(bg, normal.bg) <= BAND_MAX and legible(bg, band.fg)

    if sound then
      -- Written back unchanged. The write is what survives `hi clear`.
      set(band.group, { bg = bg })
    elseif band.fill then
      -- A code fence is a surface, so it needs one.
      set(band.group, { bg = derived or bg })
    else
      -- A heading is not. Level is already carried by its own fg and icon, and
      -- substituting one derived band for all six would say nothing that the
      -- fg does not, so the failing band is dropped rather than replaced.
      set(band.group, {})
    end
  end

  -- Both link to Code by default; that link died with `hi clear` too.
  set('RenderMarkdownCodeInline', { link = 'RenderMarkdownCode' })
  set('RenderMarkdownCodeBorder', { link = 'RenderMarkdownCode' })
end

--- Run on every colorscheme, and expose the measurement behind :ThemeReadability.
function M.attach()
  vim.api.nvim_create_autocmd('ColorScheme', { callback = M.apply })

  vim.api.nvim_create_user_command('ThemeReadability', function()
    local rows, normal = M.measure()
    local hex = function(v)
      return v and ('#%06X'):format(v) or '-'
    end
    local float = resolve 'LspFloatNormal'
    local out = {
      ('%s   Normal %s on %s   LSP float %s'):format(vim.g.colors_name or '?', hex(normal.fg), hex(normal.bg), hex(float.bg)),
      ('  %-6s %-14s %-9s %-8s %-9s %s'):format('band', 'from', 'asked', 'vs bg', 'live', 'verdict'),
    }
    for _, row in ipairs(rows) do
      local verdict
      if not row.asked then
        verdict = row.live and 'none asked -> derived' or 'no band'
      elseif row.ratio > BAND_MAX then
        verdict = 'signal colour -> repaired'
      elseif not row.readable then
        verdict = ('buries text under %.1f:1 -> repaired'):format(FG_MIN)
      else
        verdict = 'surface -> kept'
      end
      out[#out + 1] = ('  %-6s %-14s %-9s %-8s %-9s %s'):format(
        row.group,
        row.source,
        hex(row.asked),
        row.ratio and ('%.2f:1'):format(row.ratio) or '-',
        hex(row.live),
        verdict
      )
    end
    vim.notify(table.concat(out, '\n'))
  end, { desc = 'Measure the active theme’s documentation surfaces' })
end

return M
