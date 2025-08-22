---@brief
---
--- https://tombi-toml.github.io/tombi/
---
--- Language server for Tombi, a TOML toolkit.
---

---@type vim.lsp.Config
return {
  cmd = NixCmd('tombi', { 'tombi', 'lsp' }),
  filetypes = { 'toml' },
  root_markers = { 'tombi.toml', 'pyproject.toml', '.git' },
}
