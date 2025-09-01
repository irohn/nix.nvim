---@brief
---
--- https://github.com/glehmann/earthlyls
---
--- A fast language server for earthly.

---@type vim.lsp.Config
return {
  cmd = NixLspShellCmd("earthlyls"),
  filetypes = { 'earthfile' },
  root_markers = { 'Earthfile' },
}
