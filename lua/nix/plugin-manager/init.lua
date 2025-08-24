local config = require("nix.config").config

local M = {}

M.scanned_plugins_path = string.format("%s/vim-plugins.json", config.data_dir)
M._scanned = false

---@param plugin NixPluginSpec
local function validate_plugin_spec(plugin)
  if type(plugin) ~= "table" then
    return false, "Plugin spec must be a table"
  end

  local has_pkg = type(plugin.pkg) == "string"
  local has_src = plugin.src == nil or type(plugin.src) == "string"

  -- Check for named fields: { pkg = "...", src = "..." }
  if has_pkg and has_src then
    return true
  end

  return false, "Invalid plugin spec " .. vim.inspect(plugin)
end

---Search for vim plugins in nixpkgs and cache the results.
---@param rescan? boolean whether to force a rescan even if cache exists
---@param async? boolean whether to run the scan asynchronously (default: true)
---@param on_complete? fun(success: boolean) callback function called when scan completes
---@return boolean|nil returns true if scan succeeded, false if failed, or nil if async
local function scan_vim_plugins(rescan, async, on_complete)
  rescan = rescan or false
  async = async or false

  local cached_search = M.scanned_plugins_path
  local cache_exists = vim.fn.filereadable(cached_search) == 1
  if cache_exists and not rescan then
    if on_complete then on_complete(true) end
    return true
  end

  local cmd = require("nix.api.search").build_command("vimPlugins", config.nixpkgs)
  table.insert(cmd, "--json")

  if not async then
    local result = nil
    local ok = false
    local sys = vim.system(cmd, {
      text = true,
      stdout = function(err, data)
        if not err and data then
          result = (result or "") .. data
        end
      end
    }):wait()

    if sys.code == 0 and result and result ~= "" then
      ok = true
    end

    if not ok then
      if on_complete then on_complete(false) end
      return false
    end

    local cache_file = io.open(cached_search, "w")
    if not cache_file then
      if on_complete then on_complete(false) end
      return false
    end
    cache_file:write(result)
    cache_file:close()
    if on_complete then on_complete(true) end
    return true
  else
    local result = ""
    vim.system(cmd, {
      text = true,
      stdout = function(err, data)
        if not err and data then
          result = result .. data
        end
      end,
      stderr = function() end,
    }, function(proc)
      local ok = proc.code == 0 and result ~= ""
      if ok then
        local cache_file = io.open(cached_search, "w")
        if cache_file then
          cache_file:write(result)
          cache_file:close()
        else
          ok = false
        end
      end
      if on_complete then on_complete(ok) end
    end)
    return nil
  end
end

---Run a command using vim.system with async support.
---@param cmd string[] command and args
---@param on_exit? fun(success: boolean, code: integer) callback function called when command
local function run_command(cmd, on_exit)
  local job = vim.system(cmd, {
    text = true,
  }, function(obj)
    local success = obj.code == 0
    if on_exit then
      on_exit(success, obj.code)
    end
  end)
  return job
end

local function process_plugin(plugin)
  local package = plugin.pkg
  local src = plugin.src or nil
  local build_dir = config.plugin_manager.build_dir
  local plugin_name = package:match("([^/]+)$")
  local plugin_path = string.format("%s/%s", build_dir, plugin_name)

  -- check if plugin is already in build_dir
  if vim.fn.isdirectory(plugin_path) == 1 then
    return
  end

  local cmd = require("nix.api.build").build_command(
    package,
    plugin_path,
    { url = src or config.nixpkgs.url, allow_unfree = config.nixpkgs.allow_unfree }
  )

  run_command(cmd, function(success, code)
    if success then
      if config.plugin_manager.settings.notify then
        vim.schedule(function()
          vim.notify(string.format("[nix.nvim] Installed plugin %s", package), vim.log.levels.INFO)
        end)
      end
    else
      if config.plugin_manager.settings.notify then
        vim.schedule(function()
          vim.notify(string.format("[nix.nvim] Failed to install plugin %s (code %d)", package, code),
            vim.log.levels.ERROR)
        end)
      end
    end
  end)
end

---Setup function for the nix plugin-manager module.
---@param opts NixConfigPluginManager
---@return nil
function M.setup(opts)
  local build_dir = opts.build_dir
  vim.fn.mkdir(build_dir, "p")

  local plugins = opts.plugins

  if opts.settings.auto_scan then
    scan_vim_plugins(opts.settings.force_rescan, true, function()
      M._scanned = true
      if opts.settings.notify then
        vim.notify("[nix.nvim] Plugin scan complete", vim.log.levels.INFO)
      end
    end)
  end

  for _, plugin in ipairs(plugins) do
    local valid, err = validate_plugin_spec(plugin)
    if not valid then
      vim.notify(string.format("Invalid plugin spec for %: %s", vim.inspect(plugin), err), vim.log.levels.ERROR)
    end
    process_plugin(plugin)
  end
end

---Get list of available vim plugins from cache or scan
---@param force_rescan? boolean whether to force rescan
---@param async? boolean whether to run scan asynchronously if needed
---@param on_complete? fun(plugins: table|nil) callback function
---@return table|nil plugins table or nil if async
function M.get_available_plugins(force_rescan, async, on_complete)
  force_rescan = force_rescan or false
  async = async == nil and true or async
  
  local cached_search = M.scanned_plugins_path
  local cache_exists = vim.fn.filereadable(cached_search) == 1
  
  if cache_exists and not force_rescan then
    -- Read from cache
    local cache_file = io.open(cached_search, "r")
    if cache_file then
      local content = cache_file:read("*a")
      cache_file:close()
      local ok, plugins = pcall(vim.json.decode, content)
      if ok and type(plugins) == "table" then
        if on_complete then on_complete(plugins) end
        return plugins
      end
    end
  end
  
  -- Need to scan
  local scan_complete = function(success)
    if success then
      local cache_file = io.open(cached_search, "r")
      if cache_file then
        local content = cache_file:read("*a")
        cache_file:close()
        local ok, plugins = pcall(vim.json.decode, content)
        if ok and type(plugins) == "table" then
          if on_complete then on_complete(plugins) end
          return
        end
      end
    end
    if on_complete then on_complete(nil) end
  end
  
  scan_vim_plugins(force_rescan, async, scan_complete)
  return async and nil or {}
end

---Get list of installed plugins from build directory
---@return table list of installed plugin names
function M.get_installed_plugins()
  local build_dir = config.plugin_manager.build_dir
  local installed = {}
  
  if vim.fn.isdirectory(build_dir) == 1 then
    local files = vim.fn.readdir(build_dir)
    for _, file in ipairs(files) do
      local plugin_path = string.format("%s/%s", build_dir, file)
      if vim.fn.isdirectory(plugin_path) == 1 then
        table.insert(installed, file)
      end
    end
  end
  
  table.sort(installed)
  return installed
end

---Install a plugin asynchronously
---@param plugin_name string the plugin package name
---@param on_complete? fun(success: boolean, plugin_name: string) callback
function M.install_plugin_async(plugin_name, on_complete)
  local plugin_spec = { pkg = plugin_name }
  local valid, err = validate_plugin_spec(plugin_spec)
  if not valid then
    if on_complete then
      vim.schedule(function()
        on_complete(false, plugin_name)
      end)
    end
    return
  end
  
  local package = plugin_spec.pkg
  local build_dir = config.plugin_manager.build_dir
  local plugin_display_name = package:match("([^/]+)$")
  local plugin_path = string.format("%s/%s", build_dir, plugin_display_name)
  
  -- Check if already installed
  if vim.fn.isdirectory(plugin_path) == 1 then
    if on_complete then
      vim.schedule(function()
        on_complete(true, plugin_name)
      end)
    end
    return
  end
  
  local cmd = require("nix.api.build").build_command(
    package,
    plugin_path,
    { url = config.nixpkgs.url, allow_unfree = config.nixpkgs.allow_unfree }
  )
  
  run_command(cmd, function(success, code)
    if success then
      if config.plugin_manager.settings.notify then
        vim.schedule(function()
          vim.notify(string.format("[nix.nvim] Installed plugin %s", package), vim.log.levels.INFO)
        end)
      end
    else
      if config.plugin_manager.settings.notify then
        vim.schedule(function()
          vim.notify(string.format("[nix.nvim] Failed to install plugin %s (code %d)", package, code),
            vim.log.levels.ERROR)
        end)
      end
    end
    
    if on_complete then
      vim.schedule(function()
        on_complete(success, plugin_name)
      end)
    end
  end)
end

---Remove an installed plugin
---@param plugin_name string the plugin directory name
---@return boolean success
function M.remove_plugin(plugin_name)
  local build_dir = config.plugin_manager.build_dir
  local plugin_path = string.format("%s/%s", build_dir, plugin_name)
  
  if vim.fn.isdirectory(plugin_path) == 1 then
    local success = vim.fn.delete(plugin_path, "rf") == 0
    if success and config.plugin_manager.settings.notify then
      vim.notify(string.format("[nix.nvim] Removed plugin %s", plugin_name), vim.log.levels.INFO)
    elseif not success and config.plugin_manager.settings.notify then
      vim.notify(string.format("[nix.nvim] Failed to remove plugin %s", plugin_name), vim.log.levels.ERROR)
    end
    return success
  end
  
  return false
end

M.scan_vim_plugins = scan_vim_plugins
M.process_plugin = process_plugin

return M
