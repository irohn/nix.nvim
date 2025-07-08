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

	-- Build ensure_installed packages
	if config.current.ensure_installed and #config.current.ensure_installed > 0 then
		for _, package in ipairs(config.current.ensure_installed) do
			local package_path = packages_dir .. "/" .. package
			if vim.fn.isdirectory(package_path) == 0 then
				local ok, err = pcall(require("nix.api.commands").build, package)
				if not ok then
					vim.notify(
						string.format("Failed to install an ensure_installed package '%s': %s", package, err),
						vim.log.levels.ERROR
					)
				end
			end
		end
	end

	-- Mark that setup has been called explicitly
	vim.g.nix_nvim_setup_called = true
end

--- Get information about a package, returns a table with package details.
--- a directory where the package is installed, a list of binaries, and its nix store path.
---@param package_name string Name of the package
---@return table|nil Package information with keys: dir, binaries, store_path, or nil if not found
---@return string|nil Error message if package not found
M.package = function(package_name)
	local utils = require("nix.api.utils")
	local package_dir = utils.get_package_dir(package_name)
	if vim.fn.isdirectory(package_dir) == 0 then
		return nil, string.format("Package '%s' is not installed", package_name)
	end

	local binaries = utils.get_package_binaries(package_name)
	local store_path = utils.get_package_store_path(package_name)

	return {
    name = package_name,
		dir = package_dir,
		binaries = binaries,
		store_path = store_path,
	}
end

return M

-- vim: ts=2 sts=2 sw=2 et
