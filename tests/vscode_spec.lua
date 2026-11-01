-- Run: nvim --headless -u NONE -i NONE -l tests/vscode_spec.lua
-- Starts this config in a child Neovim with g:vscode set before init.lua, as vscode-neovim does.
local root = vim.fn.getcwd()
local temp = vim.fn.tempname()
vim.fn.mkdir(temp .. '/config', 'p')
assert(vim.uv.fs_symlink(root, temp .. '/config/nvim'))

local count = 0
local function check(name, fn)
  local ok, err = pcall(fn)
  if not ok then
    error(name .. ': ' .. tostring(err))
  end
  count = count + 1
  print('PASS ' .. name)
end
local function equal(a, b)
  assert(vim.deep_equal(a, b), vim.inspect(a) .. ' ~= ' .. vim.inspect(b))
end

local probe = [[
local ok, config = pcall(require, 'lazy.core.config')
local plugins = ok and vim.tbl_keys(config.plugins) or {}
table.sort(plugins)
local maps = {}
for _, lhs in ipairs { ' sf', ' sw', 'gra', '<Esc>', ' f' } do
  local map = vim.fn.maparg(lhs, 'n', false, true)
  maps[lhs] = map.desc or map.rhs or false
end
local out = {
  plugins = plugins,
  clipboard = vim.g.clipboard and vim.g.clipboard.name,
  animate = package.loaded['mini.animate'] ~= nil,
  ai = package.loaded['mini.ai'] ~= nil,
  quarto = package.loaded['quarto.runner'] ~= nil,
  maps = maps,
  errmsg = vim.v.errmsg,
}
vim.fn.writefile({ vim.json.encode(out) }, vim.env.VSCODE_SPEC_OUT)
vim.cmd 'qa!'
]]

local function run(args)
  local out = temp .. '/out.json'
  local cmd = vim.list_extend({ vim.v.progpath, '--headless', '-i', 'NONE' }, args)
  vim.list_extend(cmd, { '-c', 'lua ' .. probe })
  local result = vim.system(cmd, { env = { XDG_CONFIG_HOME = temp .. '/config', VSCODE_SPEC_OUT = out }, timeout = 60000 }):wait()
  assert(vim.uv.fs_stat(out), 'probe wrote no output; stderr: ' .. (result.stderr or ''))
  local decoded = vim.json.decode(table.concat(vim.fn.readfile(out), '\n'))
  vim.fn.delete(out)
  return decoded
end

local vscode = run {
  '--cmd',
  'let g:vscode = 1',
  '--cmd',
  "lua vim.g.vscode_clipboard = { name = 'vscode-stub' }",
}

check('init.lua loads without errors', function()
  equal(vscode.errmsg, '')
end)

check('only allowlisted plugins are enabled', function()
  equal(vscode.plugins, { 'flash.nvim', 'mini.nvim', 'vim-surround' })
end)

check('clipboard uses the vscode-neovim provider', function()
  equal(vscode.clipboard, 'vscode-stub')
end)

check('mini keeps textobjects and skips animate', function()
  equal({ ai = vscode.ai, animate = vscode.animate }, { ai = true, animate = false })
end)

check('vscode keymaps replace plugin keymaps', function()
  equal(vscode.quarto, false)
  equal(vscode.maps, {
    [' sf'] = '[S]earch [F]iles',
    [' sw'] = '[S]earch current [W]ord',
    gra = 'LSP: Code [A]ction',
    ['<Esc>'] = '<cmd>nohlsearch<CR>',
    [' f'] = '[F]ormat buffer',
  })
end)

-- options.lua alone, so the terminal clipboard branch is checked without loading every plugin.
local terminal = run { '-u', 'NONE', '--cmd', 'set rtp^=' .. vim.fn.fnameescape(root), '-c', "lua require 'options'" }

check('terminal Neovim keeps win32yank', function()
  equal(terminal.clipboard, 'win32yank')
end)

vim.fn.delete(temp, 'rf')
print(('%d checks passed'):format(count))
