return {
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    main = 'nvim-treesitter.configs', -- Sets main module to use for opts
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
    opts = {
      ensure_installed = {
        -- Shells / scripting
        'bash',
        -- C / C++
        'cpp',
        'c',
        'cmake',
        -- Diff / vim help
        'diff',
        'query',
        'vim',
        'vimdoc',
        -- Web frontend
        'html',
        'css',
        'javascript',
        'typescript',
        'tsx',
        -- Lua
        'lua',
        'luadoc',
        -- Docs / config files
        'markdown',
        'markdown_inline',
        'json',
        'jsonc',
        'yaml',
        'toml',
        -- Python / Go / Rust / Solidity / Zig / Odin
        'python',
        'rust',
        'go',
        'gomod',
        'gowork',
        'gosum',
        'solidity',
        'zig',
        'odin',
        -- Infra
        'dockerfile',
        'terraform',
        'hcl',
        -- DB / data
        'prisma',
        'sql',
        -- Misc
        'regex',
        -- New languages (Phase 4)
        'kotlin',
        'swift',
      },
      -- Autoinstall languages that are not installed
      auto_install = true,
      highlight = {
        enable = true,
        -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
        --  If you are experiencing weird indenting issues, add the language to
        --  the list of additional_vim_regex_highlighting and disabled languages for indent.
        additional_vim_regex_highlighting = { 'ruby' },
      },
      indent = { enable = true, disable = { 'ruby' } },
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ['af'] = '@function.outer',
            ['if'] = '@function.inner',
            ['ac'] = '@class.outer',
            ['ic'] = '@class.inner',
            ['aa'] = '@parameter.outer',
            ['ia'] = '@parameter.inner',
          },
        },
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = {
            [']f'] = '@function.outer',
            [']c'] = '@class.outer',
            [']a'] = '@parameter.inner',
          },
          goto_previous_start = {
            ['[f'] = '@function.outer',
            ['[c'] = '@class.outer',
            ['[a'] = '@parameter.inner',
          },
        },
        swap = {
          enable = true,
          swap_next = { ['>a'] = '@parameter.inner' },
          swap_previous = { ['<a'] = '@parameter.inner' },
        },
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
