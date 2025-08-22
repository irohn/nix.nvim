---@brief
---
--- https://github.com/coq-community/vscoq

---@type vim.lsp.Config
return {
  cmd = NixCmd('coqPackages.vscoq-language-server', { 'vscoqtop' }),
  filetypes = { 'coq' },
  root_markers = { '_CoqProject', '.git' },
}
