--- @brief
--- https://github.com/bufbuild/buf
---
--- buf beta lsp included in the cli itself
---
--- buf beta lsp is a Protobuf language server compatible with Buf modules and workspaces

---@type vim.lsp.Config
return {
  cmd = NixShellCmd('buf', { 'buf', 'beta', 'lsp', '--timeout=0', '--log-format=text' }),
  filetypes = { 'proto' },
  root_markers = { 'buf.yaml', '.git' },
}
