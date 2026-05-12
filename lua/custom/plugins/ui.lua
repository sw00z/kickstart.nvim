return {
  'OXY2DEV/ui.nvim',
  lazy = false,
  priority = 900, -- load after colorscheme (1000) but before other plugins
  opts = {
    -- ── Messages ──────────────────────────────────────────────
    message = {
      enable = true,
      wrap_notify = true, -- capture vim.notify() calls

      -- Disable showcmd floating icon above cmdline
      showcmd = false,

      -- Message window sizing — bigger, more visible
      message_winconfig = {
        border = 'rounded',
        width = math.floor(vim.o.columns * 0.5),
      },
      confirm_winconfig = {
        border = 'rounded',
        width = math.floor(vim.o.columns * 0.6),
      },
      list_winconfig = {
        border = 'rounded',
        width = math.floor(vim.o.columns * 0.7),
        height = math.floor(vim.o.lines * 0.5),
      },
      history_winconfig = {
        border = 'rounded',
        height = math.floor(vim.o.lines * 0.4),
      },
    },

    -- ── Command-line ──────────────────────────────────────────
    cmdline = {
      enable = true,

      styles = {
        -- Yes/No/Cancel prompt — colored keys
        __keymap = {
          condition = function(state)
            return string.match(state.prompt or '', '[%[%(].[%]%)]%w+') ~= nil
          end,
          title = function(state)
            local title = {}
            local colors = { 'DiagnosticOk', 'DiagnosticError', 'DiagnosticWarn', 'DiagnosticHint', 'DiagnosticInfo' }
            local idx = 1

            for key, command in string.gmatch(state.prompt, '[%[%(](.)[%]%)](%S*)') do
              local hl = colors[idx] or 'DiagnosticInfo'
              table.insert(title, {
                { ' 󰧹 ' .. (key or ''), hl },
                { ' → ' .. string.upper(key or '') .. string.gsub(command or '', '%W$', ''), 'Normal' },
              })
              idx = idx + 1
            end

            return title
          end,
          winhl = '',
        },
      },
    },

    -- ── Pop-up menu (wildmenu completion) ─────────────────────
    popupmenu = {
      enable = true,

      styles = {
        default = {
          padding_left = '  ',
          padding_right = '  ',
          icon = '  ',
          icon_hl = 'Special',
          select_hl = 'CursorLine',
        },
        ['function'] = {
          condition = function(entry)
            return entry.kind == 'f'
          end,
          icon = '  ',
          icon_hl = 'Function',
        },
        variable = {
          condition = function(entry)
            return entry.kind == 'v'
          end,
          icon = '  ',
          icon_hl = '@variable',
        },
        buffer_variable = {
          condition = function(entry)
            return string.match(entry.word or '', '^b:') ~= nil
          end,
          icon = ' 󰂡 ',
          icon_hl = 'DiagnosticInfo',
        },
        global_variable = {
          condition = function(entry)
            return string.match(entry.word or '', '^g:') ~= nil
          end,
          icon = ' 󰊢 ',
          icon_hl = 'DiagnosticHint',
        },
        command = {
          condition = function(entry)
            return entry.kind == 'c' or entry.kind == ''
          end,
          icon = '  ',
          icon_hl = 'Keyword',
        },
      },
    },
  },
  config = function(_, opts)
    require('ui').setup(opts)

    -- Override ui.nvim highlights — no tinted backgrounds, clean colorscheme-native look
    local function set_ui_highlights()
      local normal = vim.api.nvim_get_hl(0, { name = 'Normal', link = false })
      local bg = normal.bg
      local fg = normal.fg
      if not bg then
        return
      end

      local function get_fg(name)
        return vim.api.nvim_get_hl(0, { name = name, link = false }).fg or fg
      end

      local ok_fg = get_fg 'DiagnosticOk'
      local warn_fg = get_fg 'DiagnosticWarn'
      local error_fg = get_fg 'DiagnosticError'
      local info_fg = get_fg 'DiagnosticInfo'
      local hint_fg = get_fg 'DiagnosticHint'
      local func_fg = get_fg 'Function'
      local const_fg = get_fg 'Constant'

      -- Cmdline: no background tint, just colored icons on normal bg
      vim.api.nvim_set_hl(0, 'UICmdlineDefault', { link = 'Normal' })
      vim.api.nvim_set_hl(0, 'UICmdlineDefaultIcon', { fg = ok_fg, bold = true })
      vim.api.nvim_set_hl(0, 'UICmdlineSearchUp', { link = 'Normal' })
      vim.api.nvim_set_hl(0, 'UICmdlineSearchUpIcon', { fg = warn_fg, bold = true })
      vim.api.nvim_set_hl(0, 'UICmdlineSearchDown', { link = 'Normal' })
      vim.api.nvim_set_hl(0, 'UICmdlineSearchDownIcon', { fg = warn_fg, bold = true })
      vim.api.nvim_set_hl(0, 'UICmdlineLua', { link = 'Normal' })
      vim.api.nvim_set_hl(0, 'UICmdlineLuaIcon', { fg = func_fg, bold = true })
      vim.api.nvim_set_hl(0, 'UICmdlineEval', { link = 'Normal' })
      vim.api.nvim_set_hl(0, 'UICmdlineEvalIcon', { fg = func_fg, bold = true })
      vim.api.nvim_set_hl(0, 'UICmdlineSubstitute', { link = 'Normal' })
      vim.api.nvim_set_hl(0, 'UICmdlineSubstituteIcon', { fg = const_fg, bold = true })

      -- Message signs — vivid colors, no bg tint
      vim.api.nvim_set_hl(0, 'UIMessageErrorSign', { fg = error_fg, bold = true })
      vim.api.nvim_set_hl(0, 'UIMessageError', { link = 'Normal' })
      vim.api.nvim_set_hl(0, 'UIMessageWarnSign', { fg = warn_fg, bold = true })
      vim.api.nvim_set_hl(0, 'UIMessageWarn', { link = 'Normal' })
      vim.api.nvim_set_hl(0, 'UIMessageOk', { fg = ok_fg })
      vim.api.nvim_set_hl(0, 'UIMessageInfoSign', { fg = info_fg, bold = true })
      vim.api.nvim_set_hl(0, 'UIMessageInfo', { link = 'Normal' })
      vim.api.nvim_set_hl(0, 'UIMessageHint', { fg = hint_fg })
      vim.api.nvim_set_hl(0, 'UIMessageDefaultSign', { fg = hint_fg })
      vim.api.nvim_set_hl(0, 'UIMessageDefault', { link = 'Normal' })
      vim.api.nvim_set_hl(0, 'UIMessagePalette', { fg = func_fg })

      -- Popupmenu
      vim.api.nvim_set_hl(0, 'UIMenuSelect', { link = 'CursorLine' })
    end

    set_ui_highlights()
    vim.api.nvim_create_autocmd('ColorScheme', {
      callback = set_ui_highlights,
    })
  end,
}
