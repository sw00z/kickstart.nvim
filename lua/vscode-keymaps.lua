-- [[ vscode-neovim keymaps ]]
-- Same keys as the terminal config, routed to VS Code commands because the plugins behind them are disabled.
-- See https://github.com/vscode-neovim/vscode-neovim#vscode-api

---@param command string VS Code command ID
---@param args? table command arguments: a list, or a map for a single object parameter
---@return function
local function action(command, args)
  return function()
    -- Required lazily: the module exists only inside a vscode-neovim session.
    require('vscode').action(command, args and { args = args } or nil)
  end
end

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

local maps = {
  { '<leader>sf', 'workbench.action.quickOpen', '[S]earch [F]iles' },
  { '<leader>sg', 'workbench.action.findInFiles', '[S]earch by [G]rep' },
  { '<leader>sd', 'workbench.actions.view.problems', '[S]earch [D]iagnostics' },
  { '<leader>sk', 'workbench.action.openGlobalKeybindings', '[S]earch [K]eymaps' },
  { '<leader><leader>', 'workbench.action.showAllEditors', '[ ] Find open editors' },
  { '<leader>/', 'actions.find', '[/] Find in current file' },
  { '<leader>f', 'editor.action.formatDocument', '[F]ormat buffer' },
  -- grn/grr/gri defaults already reach VS Code through vscode-neovim's vim.lsp.buf shim;
  -- its code_action maps to source actions, so gra targets quick fixes directly.
  { 'gra', 'editor.action.quickFix', 'LSP: Code [A]ction' },
}
for _, map in ipairs(maps) do
  vim.keymap.set('n', map[1], action(map[2]), { desc = map[3] })
end

vim.keymap.set('n', '<leader>sw', function()
  action('workbench.action.findInFiles', { query = vim.fn.expand '<cword>' })()
end, { desc = '[S]earch current [W]ord' })

-- vim: ts=2 sts=2 sw=2 et
