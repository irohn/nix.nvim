---@brief
---
--- https://tombi-toml.github.io/tombi/
---
--- Language server for Tombi, a TOML toolkit.
---

---@type vim.lsp.Config
return {
	cmd = NixLspShellCmd("tombi", { "tombi", "lsp" }),
	filetypes = { "toml" },
	root_markers = { "tombi.toml", "pyproject.toml", ".git" },
}
