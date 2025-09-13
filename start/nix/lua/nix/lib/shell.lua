local nix = require("nix.config").options.nix
local base_command = nix.command
local nixpkgs = nix.nixpkgs
local NixPackage = require("nix.lib.package")

---@class NixShell
---@field packages NixPackage[]|string[]
local Shell = {}
Shell.__index = Shell

---Create a new NixShell instance
---@param opts string|table
--- opts = {
---   packages = NixPackage[]|string[] List of packages to include in the shell
--- }
---@return NixShell
function Shell:new(opts)
	if type(opts) == "string" then
		opts = { packages = { opts } }
	else
		opts = opts or {}
	end
	self = setmetatable({}, Shell)

	---@type NixPackage[]
	self.packages = opts.packages or {}
	assert(#self.packages > 0, "At least one package must be specified")
	for i, pkg in ipairs(self.packages) do
		if type(pkg) == "string" then
			self.packages[i] = NixPackage:new({ name = pkg })
		end
	end

	return self
end

---Generate the nix shell command
---@param args? string|string[]|nil
--- opts = {
---   args = string|string[]|nil Additional arguments to pass to the shell command (optional)
--- }
---@return table
function Shell:generate_command(args)
	if type(args) == "string" then
		args = { args }
	else
		args = args or nil
	end

	local cmd = vim.deepcopy(base_command)
	table.insert(cmd, "shell")

	for _, pkg in ipairs(self.packages) do
		table.insert(cmd, string.format("%s#%s", nixpkgs, pkg.name))
	end

	if args then
		table.insert(cmd, "--command")
		for _, arg in ipairs(args) do
			table.insert(cmd, arg)
		end
	end

	return cmd
end

---String representation of NixShell
---@return string
function Shell.__tostring()
	local pkg_names = {}
	for _, pkg in ipairs(Shell.packages) do
		table.insert(pkg_names, pkg.name)
	end
	return string.format("NixShell(packages=%s)", table.concat(pkg_names, ", "))
end

return Shell
