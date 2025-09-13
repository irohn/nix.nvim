---@brief
---
--- https://github.com/nrwl/nx-console/tree/master/apps/nxls
---
--- nxls, a language server for Nx Workspaces
---
--- `nxls` can be installed via `npm`:
--- ```sh
--- npm i -g nxls
--- ```

---@type vim.lsp.Config
return {
	cmd = NixLspShellCmd("nodejs_24", { "npx", "nxls", "--stdio" }),
	filetypes = { "json", "jsonc" },
	root_markers = { "nx.json", ".git" },
}
