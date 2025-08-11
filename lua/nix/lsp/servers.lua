local M = {}

M.configs = {
	basedpyright = {
		cmd = { "basedpyright-langserver", "--stdio" },
		nix_package_name = "basedpyright",
	},
	lua_ls = {
		cmd = { "lua-language-server" },
		nix_package_name = "lua-language-server",
	},
}

M.names = vim.tbl_keys(M.configs)

function M.configure()
	for server, config in pairs(M.configs) do
		require("nix.lsp").config(server, config.nix_package_name, config.cmd)
	end
end

return M
