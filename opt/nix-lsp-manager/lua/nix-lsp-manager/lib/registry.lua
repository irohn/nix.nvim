local Server = require("nix-lsp-manager.lib.server")
local util = require("nix.util")
local data_dir = require("nix.config").options.data_dir

local M = {}

local state = {
  _cached_configured = nil, ---@type NixLSPServer[]|nil
  configured = {}, ---@type NixLSPServer[]
  enabled_set = {}, ---@type table<string, boolean>
  cache_loaded = false,
}

-- Cache file (JSON) holding list of enabled server names
local cache_dir = data_dir .. "/nix-lsp-manager"
local cache_file = cache_dir .. "/enabled_servers.json"

local function save_enabled()
  if vim.fn.isdirectory(cache_dir) == 0 then
    vim.fn.mkdir(cache_dir, "p")
  end
  local list = {}
  for name, enabled in pairs(state.enabled_set) do
    if enabled then
      list[#list + 1] = name
    end
  end
  table.sort(list)
  local ok, encoded = pcall(vim.json.encode, list)
  if not ok then
    vim.notify("nix-lsp-manager: failed to encode enabled servers", vim.log.levels.ERROR)
    return
  end
  local success, err = util.write_file(cache_file, encoded)
  if not success then
    vim.notify("nix-lsp-manager: failed to write cache: " .. tostring(err), vim.log.levels.ERROR)
  end
end

local function load_enabled()
  if state.cache_loaded then return end
  local content = util.read_file(cache_file)
  if not content or content == "" then
    return
  end
  local ok, decoded = pcall(vim.json.decode, content)
  if not ok or type(decoded) ~= "table" then
    vim.notify("nix-lsp-manager: invalid cache file, ignoring", vim.log.levels.WARN)
    return
  end
  for _, name in ipairs(decoded) do
    state.enabled_set[name] = true
  end
  state.cache_loaded = true
end

---Discover installed servers by scanning runtimepath for lsp/*.lua
---@param recache? boolean
---@return NixLSPServer[]
local function discover(recache)
  recache = recache or false
  if not recache and state._cached_configured then
    return state._cached_configured
  end

  local files = vim.api.nvim_get_runtime_file("lsp/*.lua", true)
  local names = {}
  local seen = {}
  for _, path in ipairs(files) do
    local name = path:match("[/\\]lsp[/\\]([^/\\]+)%.lua$")
    if name and not seen[name] then
      seen[name] = true
      names[#names + 1] = name
    end
  end

  table.sort(names)
  state.configured = {}
  for _, name in ipairs(names) do
    table.insert(state.configured, Server:new(name))
  end
  state._cached_configured = state.configured

  -- Purge cache entries for servers no longer installed
  local installed_set = {}
  for _, srv in ipairs(state.configured) do installed_set[srv.name] = true end
  local changed = false
  for enabled_name in pairs(state.enabled_set) do
    if not installed_set[enabled_name] then
      state.enabled_set[enabled_name] = nil
      changed = true
    end
  end
  if changed then
    save_enabled()
  end

  return state._cached_configured
end

local function ensure_loaded()
  load_enabled()
  discover(false)
end

---Return list of installed server names
function M.list_installed()
  ensure_loaded()
  local list = {}
  for _, srv in ipairs(state.configured) do
    list[#list + 1] = srv.name
  end
  return list
end

---Return list of enabled server names (from cache)
function M.list_enabled()
  ensure_loaded()
  local list = {}
  for name, v in pairs(state.enabled_set) do
    if v then list[#list + 1] = name end
  end
  table.sort(list)
  return list
end

---Enable a server (persist) - returns true if changed
---@param name string
function M.enable(name)
  ensure_loaded()
  if not state.enabled_set[name] then
    state.enabled_set[name] = true
    save_enabled()
  end
  if vim.lsp.enable then
    vim.lsp.enable(name, true)
  end
end

---Disable a server (persist)
---@param name string
function M.disable(name)
  ensure_loaded()
  if state.enabled_set[name] then
    state.enabled_set[name] = nil
    save_enabled()
  end
  if vim.lsp.enable then
    vim.lsp.enable(name, false)
  end
end

---Toggle server enabled state
function M.toggle(name)
  ensure_loaded()
  if state.enabled_set[name] then
    M.disable(name)
  else
    M.enable(name)
  end
end

---Re-discover servers, keeping enabled cache integrity
function M.refresh()
  discover(true)
end

---Bootstrap: enable all cached servers (call during startup)
function M.bootstrap()
  load_enabled()
  discover(false)
  for name, enabled in pairs(state.enabled_set) do
    if enabled and vim.lsp.enable then
      vim.lsp.enable(name, true)
    end
  end
end

return M
