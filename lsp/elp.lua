---@brief
---
--- https://whatsapp.github.io/erlang-language-platform
---
--- ELP integrates Erlang into modern IDEs via the language server protocol and was
--- inspired by rust-analyzer.

---@type vim.lsp.Config
return {
  cmd = nixCmd('erlang-language-platform', { 'elp', 'server' }),
  filetypes = { 'erlang' },
  root_markers = { 'rebar.config', 'erlang.mk', '.git' },
}
