-- Documentation-comment generator. Treesitter-driven (reads the actual function
-- signature and pre-fills param names/types/return), which is categorically beyond
-- friendly-snippets' static docstring templates. Emits LuaSnip snippets so the
-- existing <C-l>/<C-h> jumps (cmp.lua) step through the placeholders — no new keys.
-- Coverage: C, C++, Go, Java, Rust, TS/JS, Python. Zig has no neogen template; it
-- is covered by a LuaSnip `///` snippet instead (lua/custom/snippets/zig.lua).
return {
  'danymat/neogen',
  dependencies = 'nvim-treesitter/nvim-treesitter',
  cmd = 'Neogen',
  keys = {
    {
      '<leader>cd',
      function()
        require('neogen').generate()
      end,
      desc = '[C]ode [D]oc-comment (Neogen)',
    },
    {
      '<leader>cD',
      function()
        require('neogen').generate { type = 'file' }
      end,
      desc = '[C]ode [D]oc — file header',
    },
  },
  opts = {
    snippet_engine = 'luasnip',
    languages = {
      python = { template = { annotation_convention = 'google_docstrings' } }, -- swap: 'numpydoc' | 'reST'
      typescript = { template = { annotation_convention = 'tsdoc' } },
      typescriptreact = { template = { annotation_convention = 'tsdoc' } },
      javascript = { template = { annotation_convention = 'jsdoc' } },
      rust = { template = { annotation_convention = 'rustdoc' } }, -- '///'; 'rust_alternative' = '//!'
      -- c/cpp -> doxygen, go -> godoc, java -> javadoc are correct defaults (implicit).
    },
  },
}
