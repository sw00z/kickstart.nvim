-- Telescope ⇄ Zeal offline docs.
-- Lua port of https://gitlab.com/ivan-cukic/nvim-telescope-zeal-cli (no hotpot).
-- Backed by ~/.local/bin/zeal-cli (Python venv-backed; deps isolated there).
-- <leader>sz → docset picker (every installed .docset) → page picker → the chosen
-- page renders into a bottom split docked in edgy's "Zeal" slot (see edgy.lua).
return {
  dir = vim.fn.stdpath 'config' .. '/lua/custom/zeal',
  name = 'telescope-zeal',
  dependencies = { 'nvim-telescope/telescope.nvim' },
  config = function()
    require('telescope_zeal').setup {
      -- Optional per-docset title overrides; key = .docset dir name (sans
      -- extension), e.g. ['Python_3'] = { title = 'Python 3' }. The picker
      -- auto-lists every installed docset, so this is only for renaming — unset
      -- docsets show their dir-name with underscores turned to spaces. For
      -- cleaner page rendering, add a tuned alias (to_show/to_remove) for the
      -- docset in ~/.local/bin/zeal-cli's docset_configuration table.
      documentation_sets = {},
    }
  end,
  keys = {
    {
      '<leader>sz',
      function()
        require('telescope_zeal').pick_docset()
      end,
      desc = '[S]earch [Z]eal docs',
    },
  },
}
