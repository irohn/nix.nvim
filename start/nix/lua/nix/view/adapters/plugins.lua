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

-- Providers (can be sync; list_window wrapper supports both)
function M.get_all_items()
  local reg = get_registry()
  return reg.list_available()
end

function M.get_checked_items()
  local pm = get_plugin_manager()
  return pm.get_installed_plugins()
end

function M.on_check(name, done)
  local pm = get_plugin_manager()
  -- Install plugin asynchronously
  pm.install_plugin(name, function(success)
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

return M