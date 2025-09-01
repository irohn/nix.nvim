---@brief
---
--- 🛠️ bitbake language server

---@type vim.lsp.Config
return {
  cmd = NixLspShellCmd('bitbake-language-server'),
  filetypes = { 'bitbake' },
  root_markers = { '.git' },
}
