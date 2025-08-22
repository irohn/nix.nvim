---@brief
---
--- https://github.com/nerdypepper/statix
---
--- lints and suggestions for the nix programming language

---@type vim.lsp.Config
return {
  cmd = nixCmd('statix', { 'statix', 'check', '--stdin' }),
  filetypes = { 'nix' },
  root_markers = { 'flake.nix', '.git' },
}
