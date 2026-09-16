-- [[ Setting options ]]
-- See `:help vim.opt`

vim.g.python3_host_prog = vim.fn.expand '~/.virtualenvs/neovim/bin/python3'

-- Indentation (vim-sleuth overrides these per-buffer when it detects existing style)
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true
vim.opt.smartindent = true

-- Display
-- 24-bit color, set before plugins load so colorschemes never apply under the
-- cterm fallback (tmux delays Neovim's async termguicolors auto-enable).
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.signcolumn = 'yes'
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.scrolloff = 10
vim.opt.smoothscroll = true
vim.opt.showmode = false
vim.opt.cmdheight = 1
vim.opt.laststatus = 3

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.inccommand = 'split'

-- Editing
vim.opt.undofile = true
vim.opt.confirm = true
vim.opt.virtualedit = 'block'
vim.opt.jumpoptions = 'view'

-- Splits
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.splitkeep = 'screen'

-- Performance
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300

-- Whitespace visibility
vim.opt.list = true
vim.opt.listchars = { tab = '  ', trail = '·', nbsp = '␣' }

-- Wildmenu
vim.opt.wildignore:append { '*/node_modules/*', '*/.git/*', '*/.github/*' }

-- UI chrome
vim.opt.fillchars = { eob = ' ' }
vim.opt.shortmess:append 'sI'

-- Clipboard (WSL2 → Windows via win32yank)
vim.g.clipboard = {
  name = 'win32yank',
  copy = {
    ['+'] = 'win32yank.exe -i --crlf',
    ['*'] = 'win32yank.exe -i --crlf',
  },
  paste = {
    ['+'] = 'win32yank.exe -o --lf',
    ['*'] = 'win32yank.exe -o --lf',
  },
  cache_enabled = 0,
}
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

-- Prevent auto-comment on new lines
vim.api.nvim_create_autocmd('FileType', {
  pattern = '*',
  callback = function()
    vim.opt_local.formatoptions:remove { 'r', 'o' }
  end,
})

-- vim: ts=2 sts=2 sw=2 et
