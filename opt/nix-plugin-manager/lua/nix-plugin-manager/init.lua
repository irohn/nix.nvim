local config = require("nix.config")
local Registry = require("nix-plugin-manager.lib.registry")
local Plugin = require("nix-plugin-manager.lib.plugin")

local M = {}

local state = {
  plugins = {}, ---@type table<string, NixPlugin>
  loaded_plugins = {}, ---@type table<string, boolean>
  dependency_graph = {}, ---@type table<string, string[]>
}

---Setup function for the plugin manager
function M.setup()
  local options = config.options
  
  -- Initialize the registry and start background scan
  if options.plugin_manager.enabled then
    -- Start background scan if cache doesn't exist or force_rescan is enabled
    local force_rescan = options.plugin_manager.force_rescan or false
    Registry.scan_plugins(force_rescan, function(success)
      if success and options.plugin_manager.notify then
        vim.notify("[nix-plugin-manager] Plugin scan complete", vim.log.levels.INFO)
      end
    end)
    
    -- Process configured plugins
    local plugin_specs = options.plugin_manager.plugins or {}
    for _, spec in ipairs(plugin_specs) do
      local plugin = Plugin:new(spec)
      state.plugins[plugin.name] = plugin
      
      -- Build dependency graph
      if plugin.dependencies and #plugin.dependencies > 0 then
        state.dependency_graph[plugin.name] = plugin.dependencies
      end
    end
    
    -- Install and load plugins with dependency resolution
    M.install_and_load_plugins()
  end
end

---Install all configured plugins
function M.install_and_load_plugins()
  local options = config.options
  
  -- First pass: install all plugins
  if options.plugin_manager.auto_install then
    for name, plugin in pairs(state.plugins) do
      if not plugin:is_installed() then
        vim.notify(string.format("[nix-plugin-manager] Installing plugin %s", name), vim.log.levels.INFO)
        plugin:install()
      end
    end
  end
  
  -- Second pass: load plugins with dependency resolution
  local loaded = {}
  local function load_plugin_with_deps(name)
    if loaded[name] then
      return true
    end
    
    local plugin = state.plugins[name]
    if not plugin then
      return false
    end
    
    -- Load dependencies first
    if state.dependency_graph[name] then
      for _, dep_name in ipairs(state.dependency_graph[name]) do
        local dep_plugin = state.plugins[dep_name]
        if dep_plugin then
          if not load_plugin_with_deps(dep_name) then
            vim.notify(string.format("[nix-plugin-manager] Failed to load dependency %s for %s", dep_name, name), vim.log.levels.ERROR)
            return false
          end
        else
          vim.notify(string.format("[nix-plugin-manager] Dependency %s for %s is not configured", dep_name, name), vim.log.levels.WARN)
        end
      end
    end
    
    -- Load the plugin itself
    if plugin:load() then
      loaded[name] = true
      state.loaded_plugins[name] = true
      return true
    end
    
    return false
  end
  
  -- Load all plugins
  for name, _ in pairs(state.plugins) do
    load_plugin_with_deps(name)
  end
end

---Get the registry instance
function M.get_registry()
  return Registry
end

---Install a plugin by name
---@param name string Plugin name
---@param on_complete? fun(success: boolean)
function M.install_plugin(name, on_complete)
  on_complete = on_complete or function() end
  
  local plugin = Plugin:new(name)
  plugin:install()
  on_complete(true)
end

---Remove a plugin by name
---@param name string Plugin name
function M.remove_plugin(name)
  local plugin = state.plugins[name] or Plugin:new(name)
  plugin:uninstall()
  state.loaded_plugins[name] = nil
end

---Get list of installed plugins
---@return string[]
function M.get_installed_plugins()
  return Registry.list_installed()
end

---Get list of available plugins from cache
---@return string[]
function M.get_available_plugins()
  return Registry.list_available()
end

return M
