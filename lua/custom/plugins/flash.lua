return {
  'folke/flash.nvim',
  event = 'VeryLazy',
  -- nvim-fFHighlight owns f/F; char mode would also remap t/T/;/, over it.
  ---@type Flash.Config
  opts = { modes = { char = { enabled = false } } },
  -- stylua: ignore
  keys = {
    { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
    { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    { "m", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
    { "M", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Flash Treesitter Search" },
    { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
  },
}
