local health = vim.health or require("health")
local start = health.start or health.report_start
local ok = health.ok or health.report_ok
local warn = health.warn or health.report_warn
local error = health.error or health.report_error
local info = health.info or health.report_info

local is_win = vim.api.nvim_call_function("has", { "win32" }) == 1

local dependencies = {
	{
		name = "Nix",
		url = "https://nixos.org/download/",
		package = {
			bin = "nix",
			optional = false,
			version = {
				command = "nix --version",
				string = function(output)
					return output:match("(%d+%.%d+%.%d+)")
				end,
			},
		},
	},
	{
		name = "Flake",
		url = "https://nixos.wiki/wiki/flakes",
		package = {
			bin = "flake",
			optional = true,
		},
	},
}

local M = {}

M.check = function()
	-- Operating System Check
	start("Check operating system")
	if is_win then
		error(
			"This plugin does not support Windows. Consider using WSL (Windows Subsystem for Linux) to run Neovim with Nix support."
		)
		return
	end
	ok("Operating system check passed.")

	-- Dependency Checks
	start("Check required dependencies")
	for _, dep in ipairs(dependencies) do
		local name = dep.name
		local package = dep.package
		local alert

		if package.optional then
			alert = warn
		else
			alert = error
		end

		if vim.fn.executable(package.bin) ~= 1 then
			alert(string.format("%s is not installed.", name))
			if dep.url then
				info(string.format("You can install it from: %s", dep.url))
			end
			return
		else
			if package.version then
				local version_output = vim.fn.system(package.version.command)
				if vim.v.shell_error ~= 0 then
					alert(string.format("Failed to get version for %s.", name))
					return
				end

				local version = package.version.string(version_output)
				if not version then
					alert(string.format("Could not parse version for %s.", name))
					return
				end
				ok(string.format("%s version %s is installed.", name, version))
			else
				ok(string.format("%s is installed.", name))
			end
		end
	end
end

return M

-- vim: ts=2 sts=2 sw=2 et
