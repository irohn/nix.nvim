---@brief
---
--- https://www.npmjs.com/package/@snakeskin/cli
---
--- `snakeskin cli` can be installed via `npm`:
--- ```sh
--- npm install -g @snakeskin/cli
--- ```

---@type vim.lsp.Config
return {
  cmd = NixLspShellCmd('nodejs_24', {'npx', 'snakeskin-cli', 'lsp', '--stdio' }),
  filetypes = { 'ss' },
  root_markers = { 'package.json' },
}
