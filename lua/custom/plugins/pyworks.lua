-- Pyworks: notebook IDE on top of molten + jupytext + image.
-- We pass `skip_keymaps = true` to avoid pyworks's default `<leader>j*` bindings,
-- which collide with projector's job-runner namespace inside Python/notebook
-- buffers. Cell ops live under `<leader>k*` here; kernel ops under `<leader>m*`;
-- package ops under `<leader>p*`. Existing `<leader>mi` (venv-aware MoltenInit
-- in keymaps.lua) stays as the kernel-init entry point.
return {
  'jeryldev/pyworks.nvim',
  dependencies = {
    {
      'benlubas/molten-nvim',
      version = '^1.0.0',
      build = ':UpdateRemotePlugins',
    },
    '3rd/image.nvim',
    'GCBallesteros/jupytext.nvim',
  },
  lazy = false,
  config = function()
    require('pyworks').setup {
      python = {
        preferred_venv_name = '.venv',
        use_uv = true,
      },
      auto_activate_venv = true,
      skip_keymaps = true,
    }

    -- Cell ops: buffer-local for python / quarto / markdown / ipynb
    local cell_filetypes = { 'python', 'quarto', 'markdown' }
    vim.api.nvim_create_autocmd('FileType', {
      pattern = cell_filetypes,
      callback = function(event)
        local function k(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = event.buf, silent = true, desc = desc })
        end

        -- Execution
        k('n', '<leader>kl', '<cmd>MoltenEvaluateLine<cr>', 'Run current line')
        k('v', '<leader>kr', ':<C-u>MoltenEvaluateVisual<cr>', 'Run selection')
        k('n', '<leader>kc', function()
          vim.cmd 'MoltenEvaluateOperator'
          vim.api.nvim_feedkeys('ic', 'n', false)
        end, 'Run current cell')
        k('n', '<leader>kk', '<cmd>MoltenReevaluateCell<cr>', 'Re-run current cell')

        -- Navigation
        k('n', '<leader>k]', '<cmd>PyworksNextCell<cr>', 'Next cell')
        k('n', '<leader>k[', '<cmd>PyworksPrevCell<cr>', 'Previous cell')

        -- Cell creation
        k('n', '<leader>ka', '<cmd>PyworksInsertCellAbove<cr>', 'Insert cell above')
        k('n', '<leader>kb', '<cmd>PyworksInsertCellBelow<cr>', 'Insert cell below')

        -- Cell editing
        k('n', '<leader>kt', '<cmd>PyworksToggleCellType<cr>', 'Toggle cell type')
        k('n', '<leader>kJ', '<cmd>PyworksMergeCellBelow<cr>', 'Merge with cell below')
        k('n', '<leader>ks', '<cmd>PyworksSplitCell<cr>', 'Split cell at cursor')

        -- Output
        k('n', '<leader>kd', '<cmd>MoltenDelete<cr>', 'Clear cell output')
        k('n', '<leader>ko', '<cmd>MoltenShowOutput<cr>', 'Show output window')
      end,
    })

    -- Kernel management (global; existing <leader>mi stays in keymaps.lua)
    vim.keymap.set('n', '<leader>mr', '<cmd>MoltenRestart<cr>', { desc = 'Restart kernel' })
    vim.keymap.set('n', '<leader>mx', '<cmd>MoltenInterrupt<cr>', { desc = 'Interrupt kernel' })
    vim.keymap.set('n', '<leader>mI', '<cmd>MoltenInfo<cr>', { desc = 'Kernel info' })

    -- Package management (global)
    vim.keymap.set('n', '<leader>pi', '<cmd>PyworksAdd<cr>', { desc = 'Install missing packages' })
    vim.keymap.set('n', '<leader>pS', '<cmd>PyworksSetup<cr>', { desc = 'Pyworks setup (venv + packages)' })
  end,
}
