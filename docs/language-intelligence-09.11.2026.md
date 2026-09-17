# Language intelligence and library research

Completion opens while typing and accepts flexible symbol matches. LSP candidates rank before Copilot. Tab selects the next candidate; Enter accepts only a selected candidate. Ctrl-Space requests completion, Ctrl-E cancels, Ctrl-D/Ctrl-U scroll documentation, and Ctrl-L/Ctrl-H move through snippet placeholders. Alt-E requests Emmet separately.

C++ overloads group only when their insertion text, edits, qualification, and other protocol fields agree. Different argument snippets or required headers remain separate. Grouped documentation lists signatures while acceptance preserves the original clangd edits. Servers requiring completion resolution keep native entries.

## Project analysis

| Command | Behavior |
| --- | --- |
| `:LspProfile` | Show the current root and profile |
| `:LspProfile full` | Detailed inlay hints, Go staticcheck, clang-tidy, eight clangd workers, 300 C++ completion results |
| `:LspProfile balanced` | Hide inlay hints initially, disable Go staticcheck and clang-tidy, use two clangd workers and 100 results |
| `:LspProfile reset` | Remove the project override and return to full |
| `:LspContext` | Inspect roots, executable paths, TypeScript SDK/version, formatter ownership, and external linters |
| `:Lint` | Run the configured external linter manually, including in balanced mode |

Full is the default. Choices persist by normalized language-server root in `stdpath('state')/lsp-profiles.json`. Switching a C/C++ profile restarts only that root's clangd and preserves unsaved buffers. Go settings update live. `<leader>LP` selects a profile and `<leader>LI` opens language context.

Full refreshes CodeLens on attachment and save; balanced refreshes it manually with `<leader>LC`. `<leader>Lc` runs a lens. `<leader>Lh` toggles inlay hints for the current buffer. External Go lint runs on save only in full mode; another run cancels the preceding process. Switching to balanced cancels pending Go lint.

TypeScript uses the package root and a project-installed SDK when available. Each Fleetwise application retains its own React declarations and aliases. Initial semantic indexing can take several seconds; an early hover may contain only an import name until that finishes. `:LspContext` distinguishes the configured SDK from the server's reported version.

ESLint attaches only to configured projects. On save, its fixes run before Conform formatting. Project Prettier configuration wins; the personal fallback is used only without a resolved configuration. Go formatting remains goimports followed by gofumpt.

## Research workflow

| Action | Key or command |
| --- | --- |
| Inspect a type or function | `K` |
| Inspect call arguments | `gK` |
| Keep documentation visible while editing | `<leader>Lk` |
| Navigate to definition or references | `gd`, `gr` |
| Navigate to implementation source | `<leader>LS`, `:LspSource` |
| Explore an import and its outline | `<leader>Le` |
| Browse symbol reference docs | `<leader>Ld` |
| Read installed package docs | `<leader>LD`, `:LibraryDocs` |

Start with the signature, then inspect implementation source and references for actual usage. On a JS/TS import, LibraryDocs resolves the installed package and offers its README and declared homepage/repository. Elsewhere it prompts for a package name. Local import paths use source navigation. URLs open only after selection; websites may document a newer version than the installed package.

Go uses gopls' package-documentation action, with reference docs as a fallback. C/C++ uses installed language reference docsets and source/header exploration. DevDocs reference sets are labeled separately from installed package documentation. Missing sets can be installed with `:DevdocsInstall`.

Pinned hover preserves the originating window and cursor, uses each server's position encoding, and rejects stale responses. Press `q` in the panel to close it, or use `:DocsViewToggle`.

## Build prerequisites

- Preserve each C/C++ project's standard and include paths. The O'Reilly course supplies C++26 through `.clangd`; CS144 supplies C++20 through CMake.
- CS144's root `compile_commands.json` points to `build/compile_commands.json`. Configure that project's CMake build before expecting complete indexing; Neovim does not generate build files automatically.
- Keep TypeScript, React declarations, and Go dependencies installed for the owning project. Changing editor settings does not supply missing dependencies.
- clang-tidy check selection comes from `.clangd` or `.clang-tidy`; the obsolete `--clang-tidy-checks` flag is not used.

## Verification

See [test results and rationale](language-intelligence-tests-09.11.2026.md) for every executed check and its limitations.

Run `nvim --headless -u NONE -i NONE -l tests/lsp_spec.lua` for isolated regression scenarios. Run `nvim --headless -u NONE -i NONE -l tests/lsp_runtime.lua` for live servers against the local Fleetwise and hertz-scrape projects plus temporary C/C++ buffers. These tests modify only temporary files and unsaved buffers. They need installed plugins and tools; Node child processes must be permitted by the execution environment.

In a normal Neovim session, inspect `:checkhealth vim.lsp`, `:ConformInfo`, `:LspContext`, and `:WhichKey <leader>L`. Verify the menu, snippets, pinned docs, browser opening, and profile changes in both React applications, Go, and C/C++. Headless checks do not verify terminal appearance or browser rendering.
