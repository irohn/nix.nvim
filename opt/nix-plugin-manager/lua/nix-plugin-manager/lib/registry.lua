local outlink_dir = require("nix.config").options.nix.outlink_dir
local util = require("nix.util")
local data_dir = require("nix.config").options.data_dir

local Plugin = require("nix-plugin-manager.lib.plugin")

local M = {}

local state = {
	_cached_available = nil, ---@type NixPlugin[]|nil
	available = {}, ---@type NixPlugin[]
	installed_set = {}, ---@type table<string, boolean>
}

-- Cache file (JSON) holding list of enabled server names
local cache_file = data_dir .. "/installed_plugins.json"
local available_cache_file = data_dir .. "/available_plugins.json"

function M.load_installed()
	-- load installed plugins, those are plugins inside outlink_dir dir names minus "vimPlugins."
	if vim.fn.isdirectory(outlink_dir) == 0 then
		error("Nix Plugin Manager: outlink_dir does not exist: " .. outlink_dir)
		return
	end

	local handle = vim.loop.fs_scandir(outlink_dir)
	if not handle then
		vim.notify("Nix Plugin Manager: Failed to scan outlink_dir: " .. outlink_dir, vim.log.levels.ERROR)
		return
	end
	while true do
		local name, type = vim.loop.fs_scandir_next(handle)
		if not name then
			break
		end
		if (type == "directory" or type == "link") and vim.startswith(name, "vimPlugins.") then
			local plugin_name = name:match("^vimPlugins%.(.+)$")
			if plugin_name then
				state.installed_set[plugin_name] = true
				Plugin:new(plugin_name):load()
			end
		end
	end
end

function M.discover()
	-- check if available_cache_file exists
	if vim.fn.filereadable(available_cache_file) ~= 1 then
		vim.notify("Nix Plugin Manager: Available plugins cache file not found", vim.log.levels.WARN)
		return false
	end

	local content = util.read_file(available_cache_file)
	if not content or content == "" then
		vim.notify("Nix Plugin Manager: Available plugins cache file is empty", vim.log.levels.WARN)
		return false
	end

	local ok, decoded = pcall(vim.json.decode, content)
	if not ok or type(decoded) ~= "table" then
		vim.notify("Nix Plugin Manager: Invalid available plugins cache file, ignoring", vim.log.log.levels.WARN)
		return false
	end

	state.available = {}
	for entry, _ in pairs(decoded) do
		local name = entry:match("vimPlugins%.(.+)$")
		if name then
			table.insert(state.available, Plugin:new(name))
		end
	end
end

function M.get_available(name)
	for _, plugin in ipairs(state.available) do
		if plugin.name == name then
			return plugin
		end
	end
	return nil
end

function M.list_available()
	local result = {}
	for _, plugin in ipairs(state.available) do
		table.insert(result, plugin.name)
	end
	return result
end

function M.list_installed()
	local result = state.installed_set
	return vim.tbl_keys(result)
end

function M.bootstrap()
	M.load_installed()
	M.discover()
end

return M
