---@brief
---
--- https://solargraph.org/
---
--- solargraph, a language server for Ruby
---
--- You can install solargraph via gem install.
---
--- ```sh
--- gem install --user-install solargraph
--- ```

---@type vim.lsp.Config
return {
  cmd = NixCmd('rubyPackages_3_4.solargraph', { 'solargraph', 'stdio' }),
  settings = {
    solargraph = {
      diagnostics = true,
    },
  },
  init_options = { formatting = true },
  filetypes = { 'ruby' },
  root_markers = { 'Gemfile', '.git' },
}
