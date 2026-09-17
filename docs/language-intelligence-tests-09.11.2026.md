# Language intelligence verification

Final result: 15 regression scenarios passed, the real-server integration suite passed, 14 touched Lua files parsed successfully, and formatting and Git whitespace checks passed.

## Regression scenarios

Command: `nvim --headless -u NONE -i NONE -l tests/lsp_spec.lua`

The tests load installed Neovim plugins and the actual configuration modules. Server responses, selected client APIs, browser opening, and lint processes are controlled where necessary to reproduce failure cases. Mason installer setup is disabled during testing.

| Test | What it checks | Why it matters |
| --- | --- | --- |
| Equivalent C++ overloads | Identical insertion/header edits group into one entry; signature documentation and completion-list metadata survive; input remains unchanged. | Grouping must preserve the code clangd intended to insert. |
| Distinct C++ overloads | Different namespaces, headers, snippets, resolution data, commands, and replacement ranges remain separate. Resolution-dependent entries bypass grouping. | Similar labels do not imply interchangeable completion behavior. |
| Profile persistence | Balanced survives a module reload; other roots retain full; invalid choices fail; reset restores full. | A project preference must remain local and persist between sessions. |
| Malformed profile state | Invalid JSON falls back to full with a warning. | A damaged state file must not prevent editing or disable analysis silently. |
| Profile application | Balanced changes clangd workers and analysis while preserving project flags; Go settings update the existing table. | Neovim clients retain settings references, and project compiler configuration must survive profile changes. |
| TypeScript setup | Upstream source commands remain available, formatting ownership is retained, and completion preferences reach initialization options. | Replacing upstream callbacks or placing settings at the wrong level can silently remove features. |
| ESLint setup | The upstream fix-all command survives and a project without ESLint configuration does not attach. | Avoid unwanted linting while retaining fixes in configured projects. |
| TypeScript SDK lookup | A project ancestor's TypeScript package supplies the initialized server path. | Editor analysis should use the project's compiler dependency. This fixture checks positive resolution; it does not exhaustively test every workspace layout. |
| Attachment lifecycle | Repeated setup creates one highlight callback; detaching one client preserves another provider. | Multiple language servers must not duplicate or disable each other's buffer behavior. |
| Source navigation | Multiple definition locations remain selectable; stale responses are ignored. | Navigation must respect the selected destination and the current editing position. |
| Pinned hover | UTF-16 positions are sent correctly; stale results are rejected; focus stays in the source window. | Multibyte text and delayed responses must not show documentation for the wrong symbol. |
| Installed library docs | Scoped package identity is preserved and browser opening occurs only after explicit selection. | Documentation lookup must identify the installed dependency without opening an arbitrary result automatically. |
| Save ordering | The Conform save callback invokes ESLint fixes before returning formatting options. | Formatting should operate on the fixed text. This is an ordering check, not a live ESLint execution test. |
| Go lint lifecycle | Entering/leaving insert mode does not lint; full-profile save does; repeated runs cancel prior processes; balanced cancels and suppresses automatic runs; manual lint still works; buffer removal cancels; the current module supplies cwd and target. | External lint can be expensive and must not retain stale processes or a target cached from another directory. |
| Completion behavior | Automatic triggering and flexible matching are configured; LSP sorts before Copilot; Tab selects without confirming; C++ source groups agree; ordinary Go LSP completion survives optional-source failure. | Completion must remain predictable and usable when an optional source fails. |

Malformed-state and unavailable-optional-source warnings are intentional assertions. The sandbox also prevented LuaSnip from opening its usual log file; snippet configuration still loaded. The test harness fails on Lua errors recorded by autocmds as well as direct assertion failures.

## Real-server integration

Command: `nvim --headless -u NONE -i NONE -l tests/lsp_runtime.lua`

This suite uses installed TypeScript language server, gopls, clangd, and formatters. Node subprocesses required execution outside the restricted sandbox. Tests use temporary files, temporary profile state, and unsaved buffers; they do not save changes into Fleetwise, hertz-scrape, or the courses.

| Area | Checks performed | Why |
| --- | --- | --- |
| Rental Booking and Fleetwise Home | Waited for semantic React hover; checked the project TypeScript SDK; resolved React 18 and React 19 declarations respectively; resolved `@/lib/utils`; requested `useEffect` completion and resolved its import edits; verified source-command registration; switched to balanced, checked hints disabled, and requested another hover. | Proves the two applications retain their own type declarations and aliases, and that auto-import candidates produce actual import edits. |
| hertz-scrape Go | Requested goquery hover and a `source.doc` action; repeated hover; switched to balanced; checked live staticcheck settings and hint state; requested hover again. | Proves third-party package context and documentation actions are available and profile changes preserve service. The documentation action was discovered, not launched in a browser. |
| C++ | Requested standard-library hover and completion; compared every processed candidate's insertion/header edits with the native response; repeated completion; switched to balanced; observed a new initialized clangd client with two workers; checked unsaved-buffer state and subsequent hover/completion. | Tests actual protocol payloads and the restart required to change clangd command-line settings. The fixture produced five native entries and five safe entries; only synthetic equivalent entries were expected to collapse. |
| C | Initialized clangd for a C buffer and requested `size_t` hover through `stddef.h`. | Confirms C uses its own filetype and standard-library context. This is not a complete C project build test. |
| Prettier and prettierd | Ran each on the same temporary TypeScript input with `package.json` formatting settings and asserted the exact resulting text. | Confirms both respect project configuration instead of imposing the personal fallback. |
| Go formatting | Ran the configured goimports/gofumpt chain on a temporary Go module containing an unresolved `fmt.Println` call and asserted the inserted `fmt` import. | Confirms the formatter chain performs import organization with real executables. |

The initial alias fixture used a nonexistent path. TypeScript treated it as an inferred project and did not apply the application's aliases. The corrected fixture uses an existing `App.tsx` path with unsaved replacement contents. The expected alias assertion remained unchanged and passed in both applications.

Final local timings: React semantic readiness took about 4.8–7.9 seconds, warm hover 4–6 ms, auto-import completion 357–526 ms, and resolution 43–44 ms. Go warm hover took 30 ms; C++ completion took 12–14 ms. These are individual local observations, not performance guarantees or comparative benchmarks.

## Static checks

- Neovim `loadfile` parsed all 14 touched Lua configuration and test files. This catches syntax errors without starting unrelated plugins.
- StyLua `--verify` checked AST preservation while formatting changed helpers and tests. `--check` subsequently passed for the five helper modules, both tests, and the lint specification.
- `git diff --check` passed across tracked changes, checking whitespace errors and conflict markers.

## Verification limits

Terminal menu appearance, snippet interaction, Edgy layout, rendered pinned documentation, browser pages, and downloaded DevDocs content still need observation in a normal interactive session. Live ESLint fixes and golangci-lint diagnostics were not executed against the real repositories; their configuration and scheduling paths were tested with controlled substitutes. No full application test suite or course build was run because application sources and build settings were unchanged. The CS144 compilation-database target still needs to be generated by its project build.

Restart Neovim, then use `:LspContext`, `:ConformInfo`, `:checkhealth vim.lsp`, and `:WhichKey <leader>L` for interactive verification. These are follow-up checks, not additional health-check passes claimed by this report.
