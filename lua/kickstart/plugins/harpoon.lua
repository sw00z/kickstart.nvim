return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  enabled = true,
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local harpoon = require('harpoon'):setup {}
    local conf = require('telescope.config').values
    local function toggle_telescope(harpoon_files)
      local file_paths = {}
      for _, item in ipairs(harpoon_files.items) do
        table.insert(file_paths, item.value)
      end

      require('telescope.pickers')
        .new({}, {
          prompt_title = 'Harpoon',
          finder = require('telescope.finders').new_table {
            results = file_paths,
          },
          previewer = conf.file_previewer {},
          sorter = conf.generic_sorter {},
        })
        :find()
    end

    vim.keymap.set('n', '<C-e>', function()
      toggle_telescope(harpoon:list())
    end, { desc = 'Open harpoon window' })

    vim.keymap.set('n', '<leader>ha', function()
      harpoon:list():add()
    end, { desc = 'Add file to harpoon list' })

    vim.keymap.set('n', '<C-p>', function()
      harpoon:list():prev()
    end, { desc = 'Previous file added by harpoon' })
    --
    vim.keymap.set('n', '<C-n>', function()
      harpoon:list():next()
    end, { desc = 'Next file added by harpoon' })
  end,
}

-- basic telescope configuration
