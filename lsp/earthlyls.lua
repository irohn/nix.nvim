---@brief
---
--- https://github.com/glehmann/earthlyls
---
--- A fast language server for earthly.

---@type vim.lsp.Config
return {
  cmd = require("nix").build_nix_shell_cmd("earthlyls"),
  filetypes = { 'earthfile' },
  root_markers = { 'Earthfile' },
}
