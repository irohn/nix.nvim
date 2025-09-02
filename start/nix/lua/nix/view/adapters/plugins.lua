-- Adapter for the improved list_window to manage plugins
-- Requires optional pack 'nix-plugin-manager' providing registry & plugin objects.
local M = {}

local function get_plugin_manager()
	return require("nix-plugin-manager")
end

local function get_registry()
	local pm = get_plugin_manager()
	return pm.get_registry()
end

M.config = {
	title = "Nix Plugins",
	concurrency = math.max(1, math.floor((vim.uv or vim.loop).available_parallelism() / 2)), -- ensure concurrency is never 0
	debounce = 40,
}

-- State for tracking installation progress
local installation_state = {}

-- Providers (can be sync; list_window wrapper supports both)
function M.get_all_items()
	local reg = get_registry()
	return reg.list_available()
end

function M.get_checked_items()
	local pm = get_plugin_manager()
	local installed = pm.get_installed_plugins()
	local result = {}

	-- Add installed plugins
	for _, name in ipairs(installed) do
		table.insert(result, name)
	end

	-- Add plugins currently being installed (shown as checked but with spinner)
	for name, _ in pairs(installation_state) do
		if not vim.tbl_contains(result, name) then
			table.insert(result, name)
		end
	end

	return result
end

-- Custom display function to show spinners for installing plugins
function M.get_item_display(name)
	local pm = get_plugin_manager()

	if installation_state[name] or pm.is_plugin_installing(name) then
		-- Show spinner for installing plugins
		local spinner_chars = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
		local uv = vim.uv or vim.loop
		local spinner_index = (math.floor(uv.now() / 100) % #spinner_chars) + 1
		return spinner_chars[spinner_index] .. " " .. name .. " (installing...)"
	end

	local installed = vim.tbl_contains(pm.get_installed_plugins(), name)
	local icon = installed and "◼" or "◻"
	return icon .. " " .. name
end

function M.on_check(name, done)
	local pm = get_plugin_manager()

	-- Prevent installing if already installing
	if installation_state[name] or pm.is_plugin_installing(name) then
		vim.notify(
			string.format("[nix-plugin-manager] Plugin %s is already being installed", name),
			vim.log.levels.WARN
		)
		vim.schedule(done)
		return
	end

	-- Mark as installing in our local state
	installation_state[name] = true

	-- Install plugin asynchronously
	pm.install_plugin(name, function(success)
		-- Clear our local installation state
		installation_state[name] = nil

		if success then
			vim.notify(string.format("[nix-plugin-manager] Installed plugin %s", name), vim.log.levels.INFO)
		else
			vim.notify(string.format("[nix-plugin-manager] Failed to install plugin %s", name), vim.log.levels.ERROR)
		end
		vim.schedule(done)
	end)
end

function M.on_uncheck(name, done)
	local pm = get_plugin_manager()

	-- Prevent removing if currently installing
	if installation_state[name] or pm.is_plugin_installing(name) then
		vim.notify(
			string.format("[nix-plugin-manager] Cannot remove %s: installation in progress", name),
			vim.log.levels.WARN
		)
		vim.schedule(done)
		return
	end

	-- Remove plugin
	pm.remove_plugin(name)
	vim.notify(string.format("[nix-plugin-manager] Removed plugin %s", name), vim.log.levels.INFO)
	vim.schedule(done)
end

-- Optional on_open: ensure plugins are scanned and registry is loaded
function M.on_open(self, done)
	local reg = get_registry()
	-- Force refresh of installed plugins
	reg.refresh()

	-- If no cache exists, trigger a background scan
	local available = reg.list_available()
	if #available == 0 then
		reg.scan_plugins(false, function(success)
			if success then
				vim.notify("[nix-plugin-manager] Plugin scan complete", vim.log.levels.INFO)
			end
			done()
		end)
	else
		done()
	end
end

-- Set up a timer to refresh the display periodically for spinners
local function setup_refresh_timer()
	local uv = vim.uv or vim.loop
	local timer = uv.new_timer()
	if not timer then
		return
	end

	timer:start(500, 500, function()
		vim.schedule(function()
			-- Check if any installations are in progress
			local has_installing = next(installation_state) ~= nil
			local pm = get_plugin_manager()

			-- Check plugin manager state as well
			for _, name in ipairs(pm.get_available_plugins()) do
				if pm.is_plugin_installing(name) then
					has_installing = true
					break
				end
			end

			if has_installing then
				-- Trigger UI refresh if the window is open
				local ok, ui = pcall(require, "nix.view.ui")
				if ok and ui.list_window then
					ui.list_window:refresh()
				end
			end
		end)
	end)

	return timer
end

-- Initialize refresh timer when this adapter is loaded
setup_refresh_timer()

return M
