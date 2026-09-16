-- Docked, collapsible LSP documentation panel (the nvim-docs-view UX): renders
-- hover/LSP docs in a split instead of a transient float, so the docs stay put
-- while you read and edit. The split is captured into edgy's bottom edge (see the
-- `ft = 'docs-view'` Hover view in edgy.lua) so it stacks with Notes/DevDocs and
-- collapses back to the exact cursor via edgy's goto_main — no jumplist churn.
--
-- update_mode = 'manual' (not 'auto'): auto re-issues a hover RPC + re-render on
-- every cursor move while the panel is open, which on a large file is a sustained
-- RPC stream. Manual keeps it free — refresh on demand with <leader>LK.
--
-- Keep the transient `K` float as the quick peek; <leader>Lk is the persistent
-- docked companion.
return {
  'amrbashir/nvim-docs-view',
  cmd = { 'DocsViewToggle', 'DocsViewUpdate' }, -- lazy: nothing loads at startup
  keys = {
    -- Single key: DocsViewUpdate both opens the bottom panel AND fills it with the
    -- symbol under the cursor (DocsViewToggle alone opens an empty/stale panel in
    -- manual mode). Hide it with <c-q> (edgy) or q; reopen by pressing this again.
    { '<leader>Lk', '<cmd>DocsViewUpdate<cr>', desc = '[L]SP doc[k]s panel (open/update)' },
  },
  opts = {
    position = 'bottom',
    height = 14,
    update_mode = 'manual',
  },
  config = function(_, opts)
    require('docs-view').setup(opts)
    -- The upstream request uses byte columns; build positions per client encoding.
    vim.api.nvim_create_user_command('DocsViewUpdate', function()
      require('custom.lang_docs').pinned_hover()
    end, {})
    vim.api.nvim_create_user_command('DocsViewToggle', function()
      require('custom.lang_docs').pinned_hover(true)
    end, {})
  end,
}
