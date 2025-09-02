local config = require("nix.config")

local function ensure_directories(dirs)
	for _, dir in ipairs(dirs) do
		if vim.fn.isdirectory(dir) == 0 then
			vim.fn.mkdir(dir, "p")
		end
	end
end

local M = {}

function M.setup(opts)
	config.setup(opts)
	local options = config.options

	-- create directories if they don't exist
	ensure_directories({
		options.data_dir,
		options.nix.outlink_dir,
	})

	-- Load plugin manager if enabled
	if options.plugin_manager.enabled then
		vim.api.nvim_command("packadd nix-plugin-manager")
		require("nix-plugin-manager").setup()
	end

	-- Load LSP manager if enabled
	if options.lsp_manager.enabled then
		vim.api.nvim_command("packadd nix-lsp-manager")
		require("nix-lsp-manager").setup()
	end
end

return M
