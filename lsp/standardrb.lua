---@brief
---
--- https://github.com/testdouble/standard
---
--- Ruby Style Guide, with linter & automatic code fixer.

---@type vim.lsp.Config
return {
  cmd = NixCmd('rubyPackages_3_4.standard', { 'standardrb', '--lsp' }),
  filetypes = { 'ruby' },
  root_markers = { 'Gemfile', '.git' },
}
