---@brief
---
--- 🛠️ bitbake language server

---@type vim.lsp.Config
return {
  cmd = nixCmd('bitbake-language-server'),
  filetypes = { 'bitbake' },
  root_markers = { '.git' },
}
