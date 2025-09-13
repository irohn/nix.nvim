local registry = require("nix-plugin-manager.lib.registry")

local M = {}

M.config = {
	title = "Plugins",
	concurrency = math.max(1, math.floor((vim.uv or vim.loop).available_parallelism() / 2)), -- ensure concurrency is never 0
	debounce = 40,
}

-- Providers (can be sync; list_window wrapper supports both)
function M.get_all_items()
	return registry.list_available()
end

function M.get_checked_items()
	return registry.list_installed()
end

function M.on_check(name, done)
	local plugin = registry.get_available(name)
	if not plugin then
		vim.notify("Nix Plugin Manager: Plugin not found: " .. name, vim.log.levels.ERROR)
		done()
		return
	end

	plugin:install({
		on_exit = function(obj)
			vim.schedule(function()
				if obj.code == 0 then
					registry.load_installed()
					vim.notify("Nix Plugin Manager: Installed " .. name, vim.log.levels.INFO)
					plugin:load()
					done()
				else
					vim.notify("Nix Plugin Manager: Failed to install " .. name, vim.log.levels.ERROR)
					done()
				end
			end)
		end,
	})
end

function M.on_uncheck(name, done)
	local plugin = registry.get_available(name)
	if not plugin then
		vim.notify("Nix Plugin Manager: Plugin not found: " .. name, vim.log.levels.ERROR)
		done()
		return
	end

	plugin:uninstall()
	registry.load_installed()
	done()
end

-- Optional on_open: simulate initialization
function M.on_open(_, done)
	registry.load_installed()
	done()
end

return M
