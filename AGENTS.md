# AGENTS.md — orientation for future agent sessions

A short map for Claude / Codex / any agent working in this repo. Not a tutorial — assumes you can read the code.

## Layout

```
init.lua                       Entry point. Sets leader, then requires 4 modules below.
lua/options.lua                vim.opt settings (numbers, indent, clipboard, …)
lua/lazy-bootstrap.lua         Clones lazy.nvim if missing.
lua/lazy-plugins.lua           lazy.setup({ … }) — the plugin manifest.
lua/keymaps.lua                Global, non-plugin keymaps. Quarto runner + Molten init live here.
lua/kickstart/plugins/         Kickstart-derived specs (lspconfig, conform, lint, debug,
                               treesitter, telescope, which-key, mini, cmp, harpoon, …).
                               These are MODIFIED in place from upstream — no override layer.
lua/custom/plugins/            Personal additions, auto-imported by lazy via:
                               `{ import = 'custom.plugins' }` in lazy-plugins.lua.
                               Drop a new `*.lua` here and it loads on next nvim start.
```

## Conventions

- **Plugin manager**: lazy.nvim. Plugin spec is a table returned from a file in `lua/{kickstart,custom}/plugins/`.
- **Disabling a plugin**: prefer `enabled = false` for short-lived experiments. For permanent retirement, delete the file (git is the rollback).
- **Adding a language**: 5 places to touch (kickstart files modified in place, not overridden):
  - `lua/kickstart/plugins/lspconfig.lua` → `servers = { … }` table (+ Mason ensure_installed if applicable)
  - `lua/kickstart/plugins/conform.lua`   → `formatters_by_ft = { … }`
  - `lua/kickstart/plugins/lint.lua`      → `linters_by_ft = { … }`
  - `lua/kickstart/plugins/treesitter.lua` → `ensure_installed = { … }`
  - `lua/kickstart/plugins/debug.lua`     → `mason-nvim-dap.ensure_installed` + per-language `dap.configurations.<ft>`
- **Keymaps**: prefer `keys = { … }` inside a plugin spec (lazy-loads on press). Use `vim.keymap.set` only for non-plugin global keymaps. Always set `desc = '…'` so which-key picks them up.
- **Which-key groups**: every `<leader><prefix>` namespace should have a group label in `lua/kickstart/plugins/which-key.lua` `spec` table. Add one when you introduce a new namespace.
- **Diagnostics**: virtual_text is OFF — `lsp_lines.nvim` renders inline diagnostics below the line. `<leader>l` toggles.
- **Completion**: `nvim-cmp` (NOT blink). Sources priority: lazydev, copilot, nvim_lsp, luasnip, path, signature_help. Snippets via LuaSnip.
- **AI surface**: copilot is for inline completion (suggestion/panel disabled, used as cmp source only). claudecode is the IDE bridge to Claude Code CLI. claude-fzf piles files into the Claude context. Gemini-companion is a separate sidebar. These do not overlap functionally; do not consolidate without asking.
- **DB tools**: `dadbod-grip` provides the `<leader>q*` UI. `dbee` is integrated through `nvim-projector` (a job runner that treats neotest + dbee as output backends), reached via `<leader>j*`. Don't add separate `<leader>` keymaps for dbee.
- **Notebook stack**: `pyworks` orchestrates `molten` + `jupytext` + `image`. We pass `skip_keymaps = true` and define `<leader>k*` (cell ops) + `<leader>m*` (kernel) + `<leader>p*` (packages) ourselves to avoid colliding with `<leader>j*` (projector). Existing `<leader>mi` (venv-aware MoltenInit in `lua/keymaps.lua:25-34`) stays canonical for kernel init.
- **Image rendering (WSL2)**: `image.nvim` uses kitty graphics protocol. Windows Terminal silently drops it. `lua/custom/plugins/image.lua` auto-detects `$TERM_PROGRAM` and sets `vim.g.molten_image_provider = 'none'` when not compatible, so cells produce text output cleanly.

## Daily verification

| What | How |
| ---- | --- |
| Plugins loaded | `:Lazy` |
| LSP / tools installed | `:Mason`, `:LspInfo` |
| Full health | `:checkhealth` (always start here when debugging) |
| Treesitter parsers | `:TSUpdate`, `:checkhealth nvim-treesitter` |
| Notebook health | `:checkhealth molten`, `:checkhealth provider` |
| Live keymap surface | `:WhichKey <leader>` |

## Things NOT to do

- Don't migrate to blink.cmp without an explicit ask — current nvim-cmp config has copilot prioritized via `copilot_cmp.comparators.prioritize`.
- Don't add `vim.cmd.colorscheme` calls inside individual plugin specs other than `colorschemes.lua` — the active scheme is set there (jellybeans, priority 1000).
- Don't remove `<leader>j*` projector keymaps to make room for pyworks defaults — projector is the central job runner that drives both tests and DB.
- Don't add files to `lua/custom/plugins/` that just wrap a plugin without keymaps or config; if a plugin is trigger-less it should at minimum have `cmd = { … }` or `event = '…'` to lazy-load.
- Don't commit on `master` — the git-workflow-guard hook blocks it. Branch first.

## External CLI dependencies

- **tree-sitter-cli ≤ 0.25.x** required for parsers that need source generation (currently: `swift`). Install via `cargo install tree-sitter-cli --version 0.25.10` (NOT via Volta — Volta's per-project shim breaks invocation from inside cloned grammar dirs that lack a Volta pin). nvim-treesitter (legacy branch) calls `tree-sitter generate --no-bindings --abi 15`; the `--no-bindings` flag was removed in tree-sitter-cli 0.26+, so newer versions break parser builds. Re-evaluate when nvim-treesitter switches to its "main" branch (kickstart upstream tracks this).
- **WSL2 image rendering**: Windows Terminal silently drops kitty graphics protocol; use Kitty/Wezterm/Ghostty for inline molten plots. `lua/custom/plugins/image.lua` auto-detects via `$TERM_PROGRAM` and disables `vim.g.molten_image_provider` cleanly when not compatible.

## Where the surprises live

- `lua/lazy-plugins.lua:127-352` used to hold a 226-line embedded lualine config. It now lives in `lua/custom/plugins/lualine.lua` (consolidated 2026-05-11).
- `lua/kickstart/plugins/telescope.lua:119` hardcodes `/home/swooz/` for `<leader>sm`. Personal config, intentional.
- `lua/options.lua:4` sets `vim.g.python3_host_prog = '~/.virtualenvs/neovim/bin/python3'`. The venv must exist and have `pynvim` installed or the python provider silently fails (affects molten).
- `lua/options.lua:59-73` is WSL2-specific clipboard wiring via `win32yank.exe`. On native Linux replace with xclip/xsel or remove the block entirely.
