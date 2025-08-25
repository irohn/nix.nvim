---@brief
---
--- [OpenTofu Language Server](https://github.com/opentofu/tofu-ls)
---

---@type vim.lsp.Config
return {
  cmd = NixShellCmd('tofu-ls', { 'tofu-ls', 'serve' }),
  filetypes = { 'opentofu', 'opentofu-vars' },
  root_markers = { '.terraform', '.git' },
}
