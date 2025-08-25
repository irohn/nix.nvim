---@brief
---
--- https://github.com/cue-lang/cue
---
--- CUE makes it easy to validate data, write schemas, and ensure configurations align with policies.

---@type vim.lsp.Config
return {
  cmd = NixShellCmd('cue', { 'cue', 'lsp' }),
  filetypes = { 'cue' },
  root_markers = { 'cue.mod', '.git' },
}
