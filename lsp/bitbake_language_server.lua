---@brief
---
--- 🛠️ bitbake language server

---@type vim.lsp.Config
return {
  cmd = NixCmd('bitbake-language-server'),
  filetypes = { 'bitbake' },
  root_markers = { '.git' },
}
