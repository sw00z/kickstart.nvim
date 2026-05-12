# swooz nvim config

A personal Neovim configuration. Fork of [dam9000/kickstart-modular.nvim](https://github.com/dam9000/kickstart-modular.nvim) (itself a multi-file fork of [nvim-lua/kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)).

Designed for polyglot work — Python notebooks, Solidity + Foundry, C/C++ with clangd extensions, Go, Rust, JS/TS, Zig, Odin, Swift, Kotlin, SQL, plus a Claude Code / Copilot / Gemini AI surface.

## Quick start

```sh
git clone https://github.com/sw00z/kickstart.nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
nvim
# First launch installs all plugins via lazy.nvim.
# Then run :checkhealth to verify the environment.
```

## What's in here

| Concern              | Plugin / Module                                                                  |
| -------------------- | -------------------------------------------------------------------------------- |
| Plugin manager       | `folke/lazy.nvim`                                                                |
| Completion           | `hrsh7th/nvim-cmp` + LuaSnip + copilot source                                    |
| LSP                  | `nvim-lspconfig` + Mason + mason-tool-installer + schemastore + lazydev          |
| Formatting           | `stevearc/conform.nvim` (format-on-save with prettierd / ruff / stylua / …)      |
| Linting              | `mfussenegger/nvim-lint` (ruff, shellcheck, hadolint, tflint, …)                 |
| Debugging            | `nvim-dap` + `dap-ui` + `mason-nvim-dap` + dap-virtual-text + `nvim-dap-go`      |
| Treesitter           | `nvim-treesitter` (+ textobjects: af/if, ac/ic, aa/ia, ]f/[f, ]c/[c, ]a/[a, >a/<a) |
| Tests                | `nvim-neotest/neotest` (python, go, vitest, jest, bun, playwright, foundry, hardhat, gtest, bash, zig) |
| Fuzzy finder         | `nvim-telescope/telescope.nvim` (+ fzf-native + ui-select)                       |
| File tree            | `nvim-neo-tree/neo-tree.nvim` (`\` to reveal)                                    |
| Notebooks            | `pyworks.nvim` + `molten-nvim` + `jupytext.nvim` + `quarto-nvim` + `image.nvim`  |
| Database             | `vim-dadbod` + `dadbod-grip` (UI), `nvim-dbee` (via projector backend)           |
| Job runner           | `kndndrj/nvim-projector` (drives neotest + dbee under a single `<leader>j*`)     |
| Git                  | `gitsigns.nvim`, `neogit`, `diffview.nvim`, `snacks.lazygit`                     |
| AI                   | `zbirenbaum/copilot.lua` (completion), `coder/claudecode.nvim` (IDE-mode Claude), `pittcat/claude-fzf.nvim`, `gutsavgupta/nvim-gemini-companion` |
| UI / messages        | `OXY2DEV/ui.nvim` (cmdline + popupmenu + message history), `snacks.nvim` (dashboard, indent, scroll, scratch, lazygit, gh) |
| Statusline           | `lualine.nvim` (eviline-style, config in `lua/custom/plugins/lualine.lua`)       |
| Diagnostics surface  | `lsp_lines.nvim`, `trouble.nvim`                                                 |
| Motion               | `flash.nvim` (`s` / `S` jump), `harpoon` (`<C-e>` picker, `<leader>ha` add)      |
| Colorscheme picker   | `<leader>sc` — Telescope previewer over 18 lazy-loaded themes (active: jellybeans) |

## External dependencies

Required:
- Neovim ≥ 0.10 (0.11 recommended for inlay-hint API)
- `git`, `make`, `gcc`, `unzip`, `ripgrep`, `fd`, `curl`
- A Nerd Font (set `vim.g.have_nerd_font = true` in `init.lua` if absent)

WSL2 clipboard: `win32yank.exe` on PATH (see `lua/options.lua:59-73`).

Mason-installed (auto): stylua, hadolint, tflint, vale, golangci-lint, ruff, cppcheck, prettierd, shellcheck, markdownlint, taplo, sqlfluff, sql-formatter, ktlint, and every LSP listed in `lua/kickstart/plugins/lspconfig.lua` `servers = {…}`.

System-installed (not Mason):
- **tree-sitter-cli 0.25.x** (required for the Swift treesitter parser, possibly others that need generation):
  ```sh
  cargo install tree-sitter-cli --version 0.25.10 --locked
  ```
  Do NOT install via Volta — Volta's per-project shim refuses to run from inside cloned grammar directories. nvim-treesitter (legacy) needs the `--no-bindings` flag which 0.26+ removed.
- **Swift / SwiftUI**: `sourcekit-lsp` ships with the Swift toolchain. Install Swift via `swift.org` / `brew install swift` / Linux toolchain tarball.
- **Kotlin LSP**: requires JDK 17+ on PATH. `kotlin-language-server` is Mason-installable but depends on the JDK.
- **Notebooks (molten)**: inside the neovim Python venv (`~/.virtualenvs/neovim/`):
  ```sh
  ~/.virtualenvs/neovim/bin/pip install pynvim jupyter_client nbformat pyperclip cairosvg
  ```
  After install, run `:UpdateRemotePlugins` once and restart nvim.
- **Image rendering (molten cells)**: image.nvim uses the kitty graphics protocol. Windows Terminal on WSL2 does NOT pass this protocol — use Kitty (over WSLg), Wezterm, or Ghostty for inline plots. Text output works everywhere; `image.lua` auto-detects via `$TERM_PROGRAM` and disables `molten_image_provider` when the terminal isn't compatible.

## Keymap cheat sheet

`<space>` is both leader and localleader. Authoritative source is `:WhichKey <leader>`.

| Prefix          | Group / purpose                                                                |
| --------------- | ------------------------------------------------------------------------------ |
| `<leader>a*`    | AI: `ac*` Claude (claudecode + claude-fzf), `ag*` Gemini, `ap` Copilot toggle  |
| `<leader>c*`    | Code / clangd: `ch` switch header/source, `ct` type hierarchy, `cc` call hierarchy |
| `<leader>d*`    | Debug (DAP): continue / step / breakpoints / repl / UI (also F5/F10/F11)       |
| `<leader>D*`    | Dockyard (container ops)                                                       |
| `<leader>f`     | Format buffer (conform)                                                        |
| `<leader>g*`    | Git: gitsigns hunks (`s/r/p/b/d`), `gB` GitHub browse, `gl` lazygit, `gn` neogit toggle |
| `<leader>h*`    | Harpoon (`ha` add, `<C-e>` picker, `<C-p>/<C-n>` prev/next)                    |
| `<leader>j*`    | Job runner (projector — drives neotest + dbee)                                 |
| `<leader>k*`    | Kernel / cell: cell exec, navigation, creation, edit. Buffer-local on Python/markdown/quarto. |
| `<leader>l`     | Toggle lsp_lines (inline diagnostics)                                          |
| `<leader>L*`    | LSP: `Lt` type def, `Ls/Lw` symbols, `Ln` rename, `La` code action, `Lh` inlay, `LW*` workspace |
| `<leader>m*`    | Molten / kernel: `mi` init (venv-aware), `mr` restart, `mx` interrupt, `mI` info |
| `<leader>n*`    | Notifications (ui.nvim): `nd` clear, `ns` search history                       |
| `<leader>p*`    | Packages (pyworks): `pi` install missing, `pS` :PyworksSetup                   |
| `<leader>q*`    | Database queries (dadbod-grip)                                                 |
| `<localleader>r*`| Quarto runner: `rc` cell, `ra` above, `rA` all, `rl` line, `rL` all-langs    |
| `<leader>s*`    | Search (telescope): `sf` files, `sg` grep, `sh` help, `sk` keymaps, `sc` colorschemes, `sm` $HOME, `sn` nvim config |
| `<leader>t*`    | Tests (neotest): `tt` nearest, `tf` file, `ts` summary, `to` output, `td` debug, `tw` watch |
| `<leader>x*`    | Trouble (diagnostics workspace / buffer / symbols / quickfix)                  |
| `<leader>z*`    | Zoxide directory jump                                                          |
| `s` / `S`       | Flash jump / treesitter jump (operator + visual)                                |
| `<C-w>n/X/N`    | Tab navigation: next / close / new                                              |
| `<Esc><Esc>`    | Exit terminal mode                                                              |

## Verification (daily)

```vim
:Lazy            " plugin status (sync / update / clean)
:Mason           " LSP + tool installer
:checkhealth     " full diagnosis
:WhichKey <leader>   " live keymap surface
:Telescope keymaps   " searchable keymap list
```

When something breaks:
1. `:checkhealth` first — narrows the failing subsystem.
2. `:messages` for recent errors.
3. `:Lazy log` for plugin load issues.
4. `:LspInfo` for LSP attachment.
5. `:checkhealth molten` and `:checkhealth provider` for notebook stack.

## Acknowledgement

Forked from kickstart-modular, which is forked from kickstart.nvim by TJ DeVries. Several plugin specs in `lua/custom/plugins/` are upstream patterns left intact — see the comments inside each file for source links.
