local config = require("nix.config")
local user_commands = require("nix.api.user_commands")

local M = {}

---@param opts NixConfig | nil
function M.setup(opts)
	if opts then
		config.set(opts)
	end

	-- Create the packages directory if it doesn't exist
	local data_dir = config.current.data_dir
	local packages_dir = data_dir .. "/packages"
	vim.fn.mkdir(packages_dir, "p")

	-- Initialize user commands
	user_commands.setup()

	-- -- Build ensure_installed packages
	-- if config.current.ensure_installed and #config.current.ensure_installed > 0 then
	-- 	for _, package in ipairs(config.current.ensure_installed) do
	-- 		local ok, err = pcall(require("nix.api.commands").build, package)
	-- 		if not ok then
	-- 			vim.notify(
	-- 				string.format("Failed to ensure installed package '%s': %s", package, err),
	-- 				vim.log.levels.ERROR
	-- 			)
	-- 		end
	-- 	end
	-- end

	-- Mark that setup has been called explicitly
	vim.g.nix_nvim_setup_called = true
end

return M

-- vim: ts=2 sts=2 sw=2 et
