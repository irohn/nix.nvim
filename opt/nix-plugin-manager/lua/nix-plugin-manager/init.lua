local config = require("nix.config")
local Registry = require("nix-plugin-manager.lib.registry")
local Plugin = require("nix-plugin-manager.lib.plugin")

local M = {}

local state = {
  plugins = {}, ---@type table<string, NixPlugin>
  loaded_plugins = {}, ---@type table<string, boolean>
  dependency_graph = {}, ---@type table<string, string[]>
  installing_plugins = {}, ---@type table<string, boolean>
}

-- Installation state persistence
local function get_installation_state_file()
  local options = config.options
  local data_dir = options.data_dir
  return data_dir .. "/installing-plugins.json"
end

local function save_installation_state()
  local state_file = get_installation_state_file()
  local state_dir = vim.fn.fnamemodify(state_file, ":h")
  if vim.fn.isdirectory(state_dir) == 0 then
    vim.fn.mkdir(state_dir, "p")
  end
  
  local ok, encoded = pcall(vim.json.encode, state.installing_plugins)
  if not ok then return end
  
  local fd = io.open(state_file, "w")
  if fd then
    fd:write(encoded)
    fd:close()
  end
end

local function load_installation_state()
  local state_file = get_installation_state_file()
  local fd = io.open(state_file, "r")
  if not fd then return end
  
  local content = fd:read("*a")
  fd:close()
  
  if content and content ~= "" then
    local ok, decoded = pcall(vim.json.decode, content)
    if ok and type(decoded) == "table" then
      state.installing_plugins = decoded
    end
  end
end

-- Initialize installation state on startup
load_installation_state()

-- Clean up stale installation states
local function cleanup_stale_installations()
  local changed = false
  for name, _ in pairs(state.installing_plugins) do
    local plugin = Plugin:new(name)
    if plugin:is_installed() then
      -- Plugin is installed, clear the installing state
      state.installing_plugins[name] = nil
      changed = true
    end
  end
  if changed then
    save_installation_state()
  end
end

-- Run cleanup on startup
cleanup_stale_installations()

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
  
  if not options.plugin_manager.auto_install then
    -- If auto_install is disabled, just try to load configured plugins
    M.load_configured_plugins()
    return
  end
  
  -- First pass: install all plugins that need installation
  local plugins_to_install = {}
  for name, plugin in pairs(state.plugins) do
    if not plugin:is_installed() and not state.installing_plugins[name] then
      table.insert(plugins_to_install, {name = name, plugin = plugin})
    end
  end
  
  if #plugins_to_install == 0 then
    -- No plugins need installation, proceed with loading
    M.load_configured_plugins()
    return
  end
  
  -- Install plugins one by one (to avoid overwhelming the system)
  local install_index = 1
  local function install_next()
    if install_index > #plugins_to_install then
      -- All installations complete, now load plugins
      M.load_configured_plugins()
      return
    end
    
    local item = plugins_to_install[install_index]
    local name = item.name
    
    -- Mark as installing
    state.installing_plugins[name] = true
    save_installation_state()
    vim.notify(string.format("[nix-plugin-manager] Installing plugin %s (%d/%d)", name, install_index, #plugins_to_install), vim.log.levels.INFO)
    
    item.plugin:install(function(success)
      -- Clear installing state
      state.installing_plugins[name] = nil
      save_installation_state()
      
      if success then
        vim.notify(string.format("[nix-plugin-manager] Successfully installed %s", name), vim.log.levels.INFO)
      else
        vim.notify(string.format("[nix-plugin-manager] Failed to install %s", name), vim.log.levels.ERROR)
      end
      
      install_index = install_index + 1
      install_next()
    end)
  end
  
  install_next()
end

---Load configured plugins with dependency resolution
function M.load_configured_plugins()
  local loaded = {}
  local function load_plugin_with_deps(name)
    if loaded[name] then
      return true
    end
    
    local plugin = state.plugins[name]
    if not plugin then
      return false
    end
    
    -- Skip if currently being installed
    if state.installing_plugins[name] then
      vim.notify(string.format("[nix-plugin-manager] Skipping %s: installation in progress", name), vim.log.levels.INFO)
      return false
    end
    
    -- Check if plugin is installed before attempting to load
    if not plugin:is_installed() then
      vim.notify(string.format("[nix-plugin-manager] Cannot load %s: not installed", name), vim.log.levels.WARN)
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
  
  -- Check if already installing
  if state.installing_plugins[name] then
    vim.notify(string.format("[nix-plugin-manager] Plugin %s is already being installed", name), vim.log.levels.INFO)
    on_complete(false)
    return
  end
  
  local plugin = Plugin:new(name)
  
  if plugin:is_installed() then
    vim.notify(string.format("[nix-plugin-manager] Plugin %s is already installed", name), vim.log.levels.INFO)
    on_complete(true)
    return
  end
  
  -- Mark as installing
  state.installing_plugins[name] = true
  save_installation_state()
  vim.notify(string.format("[nix-plugin-manager] Starting installation of %s", name), vim.log.levels.INFO)
  
  plugin:install(function(success)
    -- Clear installing state
    state.installing_plugins[name] = nil
    save_installation_state()
    
    if success then
      -- Add to our state if not already there
      if not state.plugins[name] then
        state.plugins[name] = plugin
      end
      vim.notify(string.format("[nix-plugin-manager] Plugin %s installed successfully", name), vim.log.levels.INFO)
    else
      vim.notify(string.format("[nix-plugin-manager] Failed to install plugin %s", name), vim.log.levels.ERROR)
    end
    on_complete(success)
  end)
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

---Check if a plugin is currently being installed
---@param name string Plugin name
---@return boolean
function M.is_plugin_installing(name)
  return state.installing_plugins[name] or false
end

return M
