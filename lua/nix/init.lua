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

	-- Mark that setup has been called explicitly
	vim.g.nix_nvim_setup_called = true
end

return M

-- vim: ts=2 sts=2 sw=2 et
