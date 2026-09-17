-- Run: nvim --headless -u NONE -i NONE -l tests/lsp_spec.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
for _, dir in ipairs(vim.fn.glob(vim.fn.stdpath 'data' .. '/lazy/*', false, true)) do
  vim.opt.rtp:append(dir)
end

local count = 0
local function check(name, fn)
  vim.v.errmsg = ''
  local ok, err = pcall(fn)
  if not ok then
    error(name .. ': ' .. tostring(err))
  end
  assert(vim.v.errmsg == '', name .. ': ' .. vim.v.errmsg)
  count = count + 1
  print('PASS ' .. name)
end
local function equal(a, b)
  assert(vim.deep_equal(a, b), vim.inspect(a) .. ' ~= ' .. vim.inspect(b))
end
local temp = vim.fn.tempname()
vim.fn.mkdir(temp, 'p')
vim.env.NVIM_LOG_FILE = temp .. '/nvim.log'
local function write(path, contents)
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  vim.fn.writefile(vim.split(contents, '\n', { plain = true }), path)
end
local stdpath = vim.fn.stdpath
vim.fn.stdpath = function(kind)
  return kind == 'state' and temp or stdpath(kind)
end

local group = require('custom.cmp_clangd_overloads').group
local function item(signature)
  return {
    label = 'make',
    filterText = 'make',
    kind = 3,
    labelDetails = { detail = signature, description = 'a::' },
    detail = 'int',
    insertTextFormat = 2,
    textEdit = { newText = 'a::make($1)', range = { start = { line = 0, character = 3 }, ['end'] = { line = 0, character = 5 } } },
    additionalTextEdits = { { range = { start = { line = 0, character = 0 }, ['end'] = { line = 0, character = 0 } }, newText = '#include <a.h>\n' } },
  }
end
check('Equivalent overloads retain exact insertions and headers', function()
  local a, b = item '(int)', item '(double)'
  local before = vim.deepcopy(a)
  local result = group { items = { a, b }, isIncomplete = true }
  equal(#result.items, 1)
  equal(result.items[1].textEdit, a.textEdit)
  equal(result.items[1].additionalTextEdits, a.additionalTextEdits)
  equal(a, before)
  assert(result.isIncomplete and result.items[1].documentation.value:find('(double)', 1, true))
end)
check('Namespaces, headers, snippets, resolve data and commands stay distinct', function()
  for _, change in ipairs {
    function(b)
      b.textEdit.newText = 'b::make($1)'
    end,
    function(b)
      b.additionalTextEdits[1].newText = '#include <b.h>\n'
    end,
    function(b)
      b.textEdit.newText = 'a::make(${1:double})'
    end,
    function(b)
      b.data = { id = 2 }
    end,
    function(b)
      b.command = { command = 'other' }
    end,
    function(b)
      b.labelDetails.description = 'b::'
    end,
    function(b)
      b.textEdit.range.start.character = 4
    end,
  } do
    local a, b = item '(int)', item '(double)'
    change(b)
    equal(#group { a, b }, 2)
  end
  equal(#group({ item '(int)', item '(double)' }, true), 2)
end)

local profiles = require 'custom.lsp_profiles'
check('Persistent profile selection, reset and invalid input', function()
  assert(profiles.set(temp, 'balanced'))
  equal(profiles.get(temp), 'balanced')
  equal(profiles.get(temp .. '/other'), 'full')
  assert(not profiles.set(temp, 'invalid'))
  package.loaded['custom.lsp_profiles'] = nil
  profiles = require 'custom.lsp_profiles'
  equal(profiles.get(temp), 'balanced')
  assert(profiles.set(temp, 'reset'))
  equal(profiles.get(temp), 'full')
end)
check('Malformed profile state uses full defaults', function()
  write(temp .. '/lsp-profiles.json', '{broken')
  package.loaded['custom.lsp_profiles'] = nil
  profiles = require 'custom.lsp_profiles'
  equal(profiles.get(temp), 'full')
end)
check('Profiles preserve project flags and live settings references', function()
  assert(profiles.set(temp, 'balanced'))
  local command = profiles.clangd_command({ 'clangd', '--clang-tidy', '-j=8', '--limit-results=300', '--query-driver=/usr/bin/clang++' }, temp)
  assert(vim.tbl_contains(command, '--clang-tidy=false'))
  assert(vim.tbl_contains(command, '-j=2'))
  assert(vim.tbl_contains(command, '--query-driver=/usr/bin/clang++'))
  local settings = { gopls = { staticcheck = true, hints = { parameterNames = true } } }
  profiles.prepare { name = 'gopls', root_dir = temp, settings = settings }
  equal(settings.gopls.staticcheck, false)
  equal(settings.gopls.hints.parameterNames, true)
  assert(profiles.set(temp, 'reset'))
end)

package.loaded['mason-tool-installer'] = { setup = function() end }
package.loaded['mason-lspconfig'] = { setup = function() end }
dofile('lua/kickstart/plugins/lspconfig.lua')[2].config()
check('TypeScript preserves upstream commands and initialization preferences', function()
  local config = vim.lsp.config.ts_ls
  local client = { server_capabilities = { codeActionProvider = { codeActionKinds = {} } } }
  config.on_attach(client, vim.api.nvim_get_current_buf())
  equal(vim.fn.exists ':LspTypescriptGoToSourceDefinition', 2)
  equal(vim.fn.exists ':LspTypescriptSourceAction', 2)
  equal(client.server_capabilities.documentFormattingProvider, false)
  assert(config.init_options.preferences.includeCompletionsForModuleExports)
  equal(config.settings.typescript.preferences, nil)
end)
check('ESLint command and project gate are preserved', function()
  vim.lsp.config.eslint.on_attach({}, vim.api.nvim_get_current_buf())
  equal(vim.fn.exists ':LspEslintFixAll', 2)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, temp .. '/project/file.ts')
  local called = false
  vim.lsp.config.eslint.root_dir(buf, function()
    called = true
  end)
  equal(called, false)
end)
check('TypeScript SDK is constrained to project ancestors', function()
  local tools = require 'custom.lsp_tools'
  write(temp .. '/sdk/.git', '')
  write(temp .. '/sdk/node_modules/typescript/package.json', '{"version":"5.6.3"}')
  write(temp .. '/sdk/node_modules/typescript/lib/tsserver.js', '')
  equal(tools.package_path(temp .. '/sdk/app', 'typescript'), temp .. '/sdk/node_modules/typescript/package.json')
  local config = { name = 'ts_ls', root_dir = temp .. '/sdk/app', init_options = {} }
  local params = {}
  vim.lsp.config.ts_ls.before_init(params, config)
  equal(params.initializationOptions.tsserver.path, temp .. '/sdk/node_modules/typescript/lib/tsserver.js')
end)

check('Repeated attachment is idempotent and detach preserves another provider', function()
  local get_clients, highlight, clear = vim.lsp.get_clients, vim.lsp.buf.document_highlight, vim.lsp.buf.clear_references
  local buf = vim.api.nvim_get_current_buf()
  local calls = 0
  local function client(id)
    return {
      id = id,
      name = 'fake',
      config = { root_dir = temp },
      supports_method = function(_, method)
        return method == 'textDocument/documentHighlight'
      end,
    }
  end
  vim.lsp.get_clients = function()
    return { client(1), client(2) }
  end
  vim.lsp.buf.document_highlight = function()
    calls = calls + 1
  end
  vim.lsp.buf.clear_references = function() end
  local attach = require 'custom.lsp_attach'
  attach.refresh(buf)
  attach.refresh(buf)
  attach.refresh(buf, 1)
  vim.api.nvim_exec_autocmds('CursorHold', { buffer = buf })
  equal(calls, 1)
  vim.lsp.get_clients, vim.lsp.buf.document_highlight, vim.lsp.buf.clear_references = get_clients, highlight, clear
end)

check('Source navigation offers all locations and ignores stale responses', function()
  local docs = require 'custom.lang_docs'
  local definition, select, get_clients = vim.lsp.buf.definition, vim.ui.select, vim.lsp.get_clients
  local callback, offered
  vim.lsp.get_clients = function()
    return {}
  end
  vim.lsp.buf.definition = function(opts)
    callback = opts.on_list
  end
  vim.ui.select = function(items)
    offered = #items
  end
  docs.source()
  callback { items = { { filename = '/tmp/a', lnum = 1, col = 1 }, { filename = '/tmp/b', lnum = 2, col = 3 } } }
  equal(offered, 2)
  docs.source()
  offered = nil
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'changed' })
  callback { items = { { filename = '/tmp/a', lnum = 1, col = 1 }, { filename = '/tmp/b', lnum = 2, col = 3 } } }
  equal(offered, nil)
  vim.lsp.buf.definition, vim.ui.select, vim.lsp.get_clients = definition, select, get_clients
end)

check('Pinned hover uses UTF-16 positions, rejects stale results and preserves focus', function()
  local docs = require 'custom.lang_docs'
  local get_clients = vim.lsp.get_clients
  vim.bo.filetype = 'typescript'
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { '"😀"; value' })
  vim.api.nvim_win_set_cursor(0, { 1, 8 })
  local win = vim.api.nvim_get_current_win()
  local reply, params
  vim.lsp.get_clients = function()
    return {
      {
        id = 100,
        offset_encoding = 'utf-16',
        request = function(_, _, p, cb)
          params, reply = p, cb
          return true, 1
        end,
        cancel_request = function() end,
      },
    }
  end
  docs.pinned_hover()
  equal(params.position.character, 6)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'changed' })
  reply(nil, { contents = { kind = 'markdown', value = 'stale' } })
  equal(#vim.api.nvim_list_wins(), 1)
  docs.pinned_hover()
  reply(nil, { contents = { kind = 'markdown', value = 'current documentation' } })
  equal(vim.api.nvim_get_current_win(), win)
  equal(#vim.api.nvim_list_wins(), 2)
  local panel
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if w ~= win then
      panel = vim.api.nvim_win_get_buf(w)
    end
  end
  equal(vim.bo[panel].filetype, 'nvim-docs-view')
  equal(vim.api.nvim_buf_get_lines(panel, 0, -1, false), { 'current documentation' })
  docs.pinned_hover(true)
  vim.lsp.get_clients = get_clients
end)

check('Installed library lookup preserves package identity and explicit browser selection', function()
  local dir = temp .. '/library'
  write(dir .. '/.git', '')
  write(
    dir .. '/node_modules/@scope/example/package.json',
    '{"version":"1.2.3","homepage":"https://example.com/docs","repository":"git+https://github.com/example/library.git"}'
  )
  write(dir .. '/node_modules/@scope/example/README.md', '# Versioned README')
  vim.api.nvim_buf_set_name(0, dir .. '/index.ts')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'import { value } from "@scope/example/subpath";' })
  vim.bo.filetype = 'typescript'
  local select, browser = vim.ui.select, vim.ui.open
  local options, choose, opened
  vim.ui.select = function(items, opts, cb)
    options, choose = items, cb
    assert(opts.prompt:find('1.2.3', 1, true))
  end
  vim.ui.open = function(url)
    opened = url
  end
  require('custom.lang_docs').library()
  equal(#options, 3)
  equal(opened, nil)
  for _, option in ipairs(options) do
    if option.url == 'https://example.com/docs' then
      choose(option)
    end
  end
  equal(opened, 'https://example.com/docs')
  vim.ui.select, vim.ui.open = select, browser
end)

check('ESLint fixes precede Conform save formatting', function()
  local tools = require 'custom.lsp_tools'
  local original = tools.eslint_fix
  local fixed
  tools.eslint_fix = function(buf)
    fixed = buf
  end
  local opts = dofile('lua/kickstart/plugins/conform.lua')[1].opts
  local result = opts.format_on_save(vim.api.nvim_get_current_buf())
  equal(fixed, vim.api.nvim_get_current_buf())
  equal(result.lsp_format, 'fallback')
  tools.eslint_fix = original
end)

check('Go lint is save-only, cancellable and rooted in the current module', function()
  local profiles = require 'custom.lsp_profiles'
  local original_lint, original_profile, original_root = package.loaded.lint, profiles.for_buffer, profiles.root
  local root = temp .. '/lint-module'
  write(root .. '/go.mod', 'module example.com/probe\n')
  vim.cmd.enew()
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(buf, root .. '/probe.go')
  vim.bo.filetype = 'go'
  local profile, runs, cancellations = 'full', 0, 0
  profiles.for_buffer = function()
    return profile
  end
  profiles.root = function()
    return root
  end
  package.loaded.lint = {
    linters = { golangcilint = { args = { 'run', 'cached-wrong-target' } } },
    lint = function(linter, opts)
      equal(opts.cwd, root)
      equal(linter.args[#linter.args], root)
      runs = runs + 1
      return {
        cancel = function()
          cancellations = cancellations + 1
        end,
      }
    end,
    get_namespace = function()
      return vim.api.nvim_create_namespace 'lint-test'
    end,
    try_lint = function()
      assert(vim.bo.filetype ~= 'go', 'Go must use its cancellable process')
    end,
  }
  dofile('lua/kickstart/plugins/lint.lua')[1].config()
  for _, event in ipairs { 'BufEnter', 'InsertLeave' } do
    vim.api.nvim_exec_autocmds(event, { buffer = buf })
  end
  equal(runs, 0)
  vim.api.nvim_exec_autocmds('BufWritePost', { buffer = buf })
  vim.api.nvim_exec_autocmds('BufWritePost', { buffer = buf })
  equal(runs, 2)
  equal(cancellations, 1)
  profile = 'balanced'
  vim.api.nvim_exec_autocmds('User', { pattern = 'LspProfileChanged', data = { root = root, profile = profile } })
  equal(cancellations, 2)
  vim.api.nvim_exec_autocmds('BufWritePost', { buffer = buf })
  equal(runs, 2)
  vim.cmd.Lint()
  equal(runs, 3)
  vim.api.nvim_buf_delete(buf, { force = true })
  equal(cancellations, 3)
  vim.api.nvim_del_augroup_by_name 'lint'
  vim.api.nvim_del_user_command 'Lint'
  package.loaded.lint, profiles.for_buffer, profiles.root = original_lint, original_profile, original_root
end)

package.loaded.cmp_go_deep = {
  new = function()
    error 'test missing optional source'
  end,
}
dofile('lua/kickstart/plugins/cmp.lua')[1].config()
check('Automatic flexible completion, explicit acceptance and LSP-first ordering', function()
  local cmp = require 'cmp'
  local config = cmp.get_config()
  equal(config.completion.autocomplete, { 'TextChanged' })
  equal(config.matching.disallow_fuzzy_matching, false)
  local compare = config.sorting.comparators[1]
  assert(compare({ source = { name = 'nvim_lsp' } }, { source = { name = 'copilot' } }))
  local visible, next_item, confirm = cmp.visible, cmp.select_next_item, cmp.confirm
  local selected, accepted = 0, 0
  cmp.visible = function()
    return true
  end
  cmp.select_next_item = function()
    selected = selected + 1
  end
  cmp.confirm = function()
    accepted = accepted + 1
  end
  config.mapping['<Tab>'].i(function()
    error 'unexpected fallback'
  end)
  equal(selected, 1)
  equal(accepted, 0)
  cmp.visible, cmp.select_next_item, cmp.confirm = visible, next_item, confirm
  vim.bo.filetype = 'cpp'
  local groups = {}
  for _, source in ipairs(cmp.get_config().sources) do
    groups[source.name] = source.group_index
  end
  equal(groups.clangd_overloads, groups.copilot)
  vim.bo.filetype = 'go'
  assert(vim.iter(cmp.get_config().sources):any(function(source)
    return source.name == 'nvim_lsp'
  end))
end)

print(('Passed %d regression scenarios'):format(count))
vim.fn.stdpath = stdpath
vim.cmd 'qa!'
