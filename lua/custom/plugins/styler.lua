-- styler.nvim: a different colorscheme for prose / non-code filetypes, set
-- per-window so markdown, text, etc. read in a softer theme without changing the
-- global (code) colorscheme. Change the prose theme by editing `prose` below.
--
-- NOTE: styler applies a theme by firing `:colorscheme` into an isolated window
-- highlight namespace. It sets eventignore = 'all' first, so those switches emit
-- no ColorScheme event today; publishing the name below lets colorschemes.lua
-- guard its persistence autocmd anyway, without a hardcoded copy to keep in sync.
return {
  'folke/styler.nvim',
  event = 'VeryLazy',
  config = function()
    -- One theme for every prose filetype.
    local prose = 'catppuccin-mocha'
    -- Read by the persistence autocmd in custom/plugins/colorschemes.lua.
    vim.g.styler_prose = prose
    require('styler').setup {
      themes = {
        markdown = { colorscheme = prose },
        text = { colorscheme = prose },
        gitcommit = { colorscheme = prose },
        rst = { colorscheme = prose },
        asciidoc = { colorscheme = prose },
        org = { colorscheme = prose },
        help = { colorscheme = prose },
      },
    }
  end,
}
