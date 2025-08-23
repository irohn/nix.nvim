---@brief
---
--- https://github.com/withered-magic/starpls
---
--- `starpls` is an LSP implementation for Starlark. Installation instructions can be found in the project's README.

---@type vim.lsp.Config
return {
  cmd = NixShellCmd('starpls'),
  filetypes = { 'bzl' },
  root_markers = { 'WORKSPACE', 'WORKSPACE.bazel', 'MODULE.bazel' },
}
