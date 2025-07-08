local config = require("nix.config").current
local uv = vim.uv or vim.loop

local M = {}

--- Get al binaries of a package
--- @param package_name string Name of the package
--- @return table List of binaries for the package
--- @return string|nil Error message if the package is not found
M.get_package_binaries = function(package_name)
	local bin_dir = config.data_dir .. "/packages/" .. package_name .. "/bin"
	local binaries = {}

	-- Check if the package directory exists
	if vim.fn.isdirectory(bin_dir) ~= 1 then
		return binaries, "Package not found: " .. package_name
	end

	-- Get all entries in the bin directory
	local entries = vim.fn.readdir(bin_dir)
	for _, entry in ipairs(entries) do
		table.insert(binaries, entry)
	end

	return binaries
end

--- Get all installed packages from the data directory
--- @return table List of package names that are installed
M.get_installed_packages = function(packages_dir)
	packages_dir = config.data_dir .. "/packages"
	local packages = {}

	-- Check if data directory exists
	if vim.fn.isdirectory(packages_dir) ~= 1 then
		return packages
	end

	-- Get all entries in the data directory
	local entries = vim.fn.readdir(packages_dir)

	-- Filter for directories and symlinks (packages)
	for _, entry in ipairs(entries) do
		local full_path = packages_dir .. "/" .. entry
		-- Check if it's a directory or a symlink (both indicate installed packages)
		if vim.fn.isdirectory(full_path) == 1 or vim.fn.getftype(full_path) == "link" then
			table.insert(packages, entry)
		end
	end

	return packages
end

--- Get a package's Nix store path using readlink
--- @param package_name string Name of the package
--- @return string|nil Nix store path of the package or nil if not found
M.get_package_store_path = function(package_name)
	local store_path = config.data_dir .. "/packages/" .. package_name
	-- Use readlink to get the actual path if it's a symlink
	if vim.fn.isdirectory(store_path) == 1 or vim.fn.getftype(store_path) == "link" then
		return uv.fs_readlink(store_path)
	end
	return nil
end

return M

-- vim: ts=2 sts=2 sw=2 et
