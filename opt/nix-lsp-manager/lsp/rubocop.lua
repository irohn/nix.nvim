---@brief
---
--- https://github.com/rubocop/rubocop

---@type vim.lsp.Config
return {
  cmd = NixLspShellCmd('rubocop', { 'rubocop', '--lsp' }),
  filetypes = { 'ruby' },
  root_markers = { 'Gemfile', '.git' },
}
