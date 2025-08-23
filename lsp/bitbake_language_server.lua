---@brief
---
--- 🛠️ bitbake language server

---@type vim.lsp.Config
return {
  cmd = NixShellCmd('bitbake-language-server'),
  filetypes = { 'bitbake' },
  root_markers = { '.git' },
}
