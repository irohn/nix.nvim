---@brief
---
--- https://github.com/marko-js/language-server
---
--- Using the Language Server Protocol to improve Marko's developer experience.
---
--- Can be installed via npm:
--- ```
--- npm i -g @marko/language-server
--- ```

---@type vim.lsp.Config
return {
  cmd = nixCmd('nodejs_24', {'npx', 'marko-language-server', '--stdio' }),
  filetypes = { 'marko' },
  root_markers = { '.git' },
}
