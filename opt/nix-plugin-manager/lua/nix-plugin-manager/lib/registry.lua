local config = require("nix.config")
local Search = require("nix.lib.search")

local Registry = {}
Registry.__index = Registry

local state = {
  _cached_available = nil, ---@type table<string, any>|nil
  available = {}, ---@type table<string, any>
  installed_set = {}, ---@type table<string, boolean>
  cache_loaded = false,
  scan_in_progress = false,
}

-- Cache file (JSON) holding list of available vimPlugins from nixpkgs
local function get_cache_file()
  local options = config.options
  local data_dir = options.data_dir
  return data_dir .. "/scanned-plugins.json"
end

local function read_file(path)
  local fd = io.open(path, "r")
  if not fd then return nil end
  local content = fd:read("*a")
  fd:close()
  return content
end

local function write_file(path, content)
  local ok, err
  local fd
  fd, err = io.open(path, "w")
  if not fd then
    return false, err
  end
  fd:write(content)
  fd:close()
  return true
end

local function save_available(plugins_data)
  local cache_file = get_cache_file()
  local cache_dir = vim.fn.fnamemodify(cache_file, ":h")
  if vim.fn.isdirectory(cache_dir) == 0 then
    vim.fn.mkdir(cache_dir, "p")
  end
  
  local ok, encoded = pcall(vim.json.encode, plugins_data)
  if not ok then
    vim.notify("nix-plugin-manager: failed to encode available plugins", vim.log.levels.ERROR)
    return
  end
  local success, err = write_file(cache_file, encoded)
  if not success then
    vim.notify("nix-plugin-manager: failed to write cache: " .. tostring(err), vim.log.levels.ERROR)
  end
end

local function load_available()
  if state.cache_loaded then return end
  state.cache_loaded = true
  
  local cache_file = get_cache_file()
  local content = read_file(cache_file)
  if not content or content == "" then
    return
  end
  local ok, decoded = pcall(vim.json.decode, content)
  if not ok or type(decoded) ~= "table" then
    vim.notify("nix-plugin-manager: invalid cache file, ignoring", vim.log.levels.WARN)
    return
  end
  state.available = decoded
  state._cached_available = decoded
end

---Scan for vimPlugins in nixpkgs and cache the results
---@param force_rescan? boolean whether to force a rescan even if cache exists
---@param async? boolean whether to run the scan asynchronously (default: true)
---@param on_complete? fun(success: boolean) callback function called when scan completes
local function scan_vim_plugins(force_rescan, async, on_complete)
  force_rescan = force_rescan or false
  if async == nil then async = true end
  on_complete = on_complete or function() end

  -- If not forcing rescan and cache exists, skip
  if not force_rescan then
    local cache_file = get_cache_file()
    if vim.fn.filereadable(cache_file) == 1 then
      load_available()
      on_complete(true)
      return
    end
  end

  -- Prevent multiple simultaneous scans
  if state.scan_in_progress then
    on_complete(false)
    return
  end

  state.scan_in_progress = true
  
  local search = Search:new("vimPlugins")
  
  local function process_results(success, result)
    state.scan_in_progress = false
    if success and result then
      local ok, parsed = pcall(vim.json.decode, result)
      if ok and type(parsed) == "table" then
        state.available = parsed
        state._cached_available = parsed
        save_available(parsed)
        on_complete(true)
        return
      end
    end
    vim.notify("nix-plugin-manager: failed to scan vimPlugins", vim.log.levels.ERROR)
    on_complete(false)
  end

  if async then
    vim.system(search.command, {
      text = true,
      timeout = 30000, -- 30 second timeout
    }, function(obj)
      vim.schedule(function()
        process_results(obj.code == 0, obj.stdout)
      end)
    end)
  else
    local obj = vim.system(search.command, { text = true, timeout = 30000 }):wait()
    process_results(obj.code == 0, obj.stdout)
  end
end

---Discover installed plugins by scanning the plugin build directory
---@param recache? boolean
---@return string[]
local function discover_installed(recache)
  recache = recache or false
  if not recache and next(state.installed_set) then
    local list = {}
    for name, installed in pairs(state.installed_set) do
      if installed then
        list[#list + 1] = name
      end
    end
    return list
  end

  local build_dir = config.options.plugin_manager.build_dir or (config.options.nix.outlink_dir .. "/plugins")
  if vim.fn.isdirectory(build_dir) == 0 then
    return {}
  end

  local handle = vim.loop.fs_scandir(build_dir)
  if not handle then
    return {}
  end

  local plugins = {}
  state.installed_set = {}
  while true do
    local name, t = vim.loop.fs_scandir_next(handle)
    if not name then break end
    if t == 'directory' then
      -- Remove vimPlugins. prefix if present
      local clean_name = name:gsub("^vimPlugins%.", "")
      plugins[#plugins + 1] = clean_name
      state.installed_set[clean_name] = true
    elseif t == 'link' then
      -- Resolve symlink and include if it points to a directory
      local stat = vim.loop.fs_stat(build_dir .. "/" .. name)
      if stat and stat.type == 'directory' then
        local clean_name = name:gsub("^vimPlugins%.", "")
        plugins[#plugins + 1] = clean_name
        state.installed_set[clean_name] = true
      end
    end
  end
  
  table.sort(plugins)
  return plugins
end

local function ensure_loaded()
  load_available()
  discover_installed(false)
end

---Return list of available plugin names (from cache)
function Registry.list_available()
  ensure_loaded()
  local list = {}
  for name, _ in pairs(state.available) do
    local clean_name = name:match("vimPlugins%.(.+)$")
    if clean_name then
      list[#list + 1] = clean_name
    end
  end
  table.sort(list)
  return list
end

---Return list of installed plugin names
function Registry.list_installed()
  ensure_loaded()
  return discover_installed(false)
end

---Check if a plugin is installed
---@param name string
---@return boolean
function Registry.is_installed(name)
  ensure_loaded()
  return state.installed_set[name] or false
end

---Force refresh of plugin discovery
function Registry.refresh()
  discover_installed(true)
end

---Initiate background scan of vimPlugins
---@param force_rescan? boolean
---@param on_complete? fun(success: boolean)
function Registry.scan_plugins(force_rescan, on_complete)
  scan_vim_plugins(force_rescan, true, on_complete)
end

---Get plugin info from cache
---@param name string
---@return table|nil
function Registry.get_plugin_info(name)
  ensure_loaded()
  local full_name = "vimPlugins." .. name
  return state.available[full_name]
end

return Registry