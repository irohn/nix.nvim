---@brief
--- https://github.com/Davidyz/VectorCode
---
--- A Language Server Protocol implementation for VectorCode, a code repository indexing tool.

---@type vim.lsp.Config
return {
  cmd = NixShellCmd('vectorcode', { 'vectorcode-server' }),
  root_dir = vim.fs.root(0, { '.vectorcode', '.git' }),
  settings = {},
}
