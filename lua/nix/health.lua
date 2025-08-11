local info = vim.health.info or vim.health.report_info
local start = vim.health.start or vim.health.report_start
local ok = vim.health.ok or vim.health.report_ok
local warn = vim.health.warn or vim.health.report_warn
local error = vim.health.error or vim.health.report_error

local is_win = vim.api.nvim_call_function("has", { "win32" }) == 1

local M = {}

function M.check()
	start("operating system")
	if is_win then
		error("Nix.nvim does not support Windows.")
		info("Consider using WSL (Windows Subsystem for Linux) to run Nix.nvim.")
	else
		ok("Operating system is supported.")
	end

	start("nix")
	if vim.fn.executable("nix") == 1 then
		ok("Nix is installed.")
	else
		error("Nix is not installed. Please install Nix to use this plugin.")
	end
end

return M

-- vim: ts=2 sts=2 sw=2 et
