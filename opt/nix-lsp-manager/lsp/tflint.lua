---@brief
---
--- https://github.com/terraform-linters/tflint
---
--- A pluggable Terraform linter that can act as lsp server.
--- Installation instructions can be found in https://github.com/terraform-linters/tflint#installation.

---@type vim.lsp.Config
return {
	cmd = NixLspShellCmd("tflint", { "tflint", "--langserver" }),
	filetypes = { "terraform" },
	root_markers = { ".terraform", ".git", ".tflint.hcl" },
}
