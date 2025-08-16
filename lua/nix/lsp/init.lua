local utils = require("nix.utils")
local config = require("nix.config").config

local M = {}

---Internal: decode JSON array of strings; returns {} on malformed input with warning.
---@param text string
---@param path string
---@return string[] servers
function M.decode_server_list(text, path)
  if text == "" then
    return {}
  end
  local ok, decoded = pcall(vim.fn.json_decode, text)
  if not ok or type(decoded) ~= "table" then
    vim.notify(
      ("[nix.lsp] Invalid JSON in cache '%s'; ignoring and resetting: %s")
      :format(path, ok and "not an array" or decoded),
      vim.log.levels.WARN
    )
    return {}
  end
  -- Filter only strings
  local out = {}
  for _, v in ipairs(decoded) do
    if type(v) == "string" and v ~= "" then
      out[#out + 1] = v
    end
  end
  return out
end

---Internal: write JSON array to file (directories auto-created).
---@param path string
---@param servers string[]
---@return boolean ok
---@return string? err
function M.write_server_list(path, servers)
  local dir = vim.fn.fnamemodify(path, ":h")
  if dir ~= "" and vim.fn.isdirectory(dir) == 0 then
    local mk_ok = vim.fn.mkdir(dir, "p")
    if mk_ok == 0 then
      return false, ("failed to create directory '%s'"):format(dir)
    end
  end
  local json = vim.fn.json_encode(servers)
  local ok, err = pcall(vim.fn.writefile, { json }, path)
  if not ok then
    return false, ("failed to write cache file '%s': %s"):format(path, err)
  end
  return true
end

--- Return the list of available LSP server names discovered in the runtimepath.
---
--- Scans every entry in 'runtimepath' for Lua files directly under an `lsp/` directory
--- (i.e. `<rtp>/.../lsp/<name>.lua`). The `.lua` extension is stripped and each name
--- is returned once. Results are sorted alphabetically.
---
--- NOTE:
---  * Only files directly inside an `lsp` directory are considered (no recursion).
---  * Path separator agnostic (works on Unix and Windows).
---  * If you need to re-scan after modifying runtimepath, call with `force_rescan = true`.
---
---@param force_rescan? boolean  If true, bypasses the cache and rescans.
---@return string[] names  Sorted unique server names.
function M.get_runtime_lsp_server_names(force_rescan)
  if not force_rescan and M._cached_lsp_servers then
    return M._cached_lsp_servers
  end

  local names = {}
  local seen = {}

  -- true => search all runtimepath entries
  local files = vim.api.nvim_get_runtime_file("lsp/*.lua", true)
  for _, path in ipairs(files) do
    -- Match .../lsp/<name>.lua with either / or \ as separators
    local name = path:match("[/\\]lsp[/\\]([^/\\]+)%.lua$")
    if name and not seen[name] then
      seen[name] = true
      names[#names + 1] = name
    end
  end

  table.sort(names)
  M._cached_lsp_servers = names
  return names
end

function M.get_enabled_servers(cache_file)
  -- Read existing cached servers
  local lines, rerr = utils.read_lines(cache_file)
  if not lines then
    return {}, rerr
  end
  local cached = M.decode_server_list(table.concat(lines, "\n"), cache_file)
  return cached
end

function M.enable_servers(servers)
  if type(servers) ~= "table" then
    vim.notify("Expected a table of servers to enable", vim.log.levels.ERROR)
    return false, "Invalid servers table"
  end

  local enabled_servers = M.get_enabled_servers(config.lsp.cache_file)

  for _, server in ipairs(servers) do
    -- Only call vim.lsp.enable if available (might not be in headless mode)
    if vim.lsp and vim.lsp.enable then
      vim.lsp.enable(server, true)
    end
    if not vim.tbl_contains(enabled_servers, server) then
      table.insert(enabled_servers, server)
    end
  end
  local changed, err = M.write_server_list(config.lsp.cache_file, enabled_servers)
  if not changed then
    vim.notify("Failed to write to data file: " .. (err or ""), vim.log.levels.ERROR)
  end

  return changed, err
end

function M.disable_servers(servers)
  if type(servers) ~= "table" then
    vim.notify("Expected a table of servers to disable", vim.log.levels.ERROR)
    return false, "Invalid servers table"
  end

  local enabled_servers = M.get_enabled_servers(config.lsp.cache_file)
  for _, server in ipairs(servers) do
    -- Only call vim.lsp.enable if available (might not be in headless mode)
    if vim.lsp and vim.lsp.enable then
      vim.lsp.enable(server, false)
    end
    enabled_servers = vim.tbl_filter(function(s)
      return s ~= server
    end, enabled_servers)
  end

  local changed, err = M.write_server_list(config.lsp.cache_file, enabled_servers)
  if not changed then
    vim.notify("Failed to write to data file: " .. (err or ""), vim.log.levels.ERROR)
  end

  return changed, err
end

---Setup cached LSP servers based on configuration.
---
--- Behavior (opts.enabled):
---   * false / nil: Do nothing (just ensure cache file exists); returns {}.
---   * true: Enable only the servers listed in the cache file.
---   * string[]: Merge the provided list with the cache file contents; enable union; update cache if new servers added.
---
--- Cache file format: JSON array of server names, e.g. ["lua_ls","pyright"].
--- On malformed JSON the file is ignored and treated as empty; a warning is shown.
---
--- Returns the list of servers actually passed to vim.lsp.enable (may be empty).
---
---@param opts NixConfigLsp
---@return string[] enabled_servers
---@return string? err  -- non-nil only if a hard error occurred (e.g., cannot create cache file, missing vim.lsp.enable)
function M.setup(opts)
  -- Basic validation of opts fields
  if type(opts) ~= "table" then
    return {}, "opts must be a table"
  end

  local mode = opts.enabled
  local mode_t = type(mode)
  if not (mode_t == "boolean" or mode_t == "table" or mode == nil) then
    return {}, "opts.enabled must be boolean, string[] or nil"
  end
  if mode_t == "table" then
    for i, v in ipairs(mode) do
      if type(v) ~= "string" or v == "" then
        return {}, ("opts.enabled[%d] must be a non-empty string"):format(i)
      end
    end
  end

  local cache_file = opts.cache_file
  if type(cache_file) ~= "string" or cache_file == "" then
    return {}, "opts.cache_file must be a non-empty string"
  end

  -- Ensure cache file exists (create empty array if missing)
  if vim.fn.filereadable(cache_file) == 0 then
    local ok, err = M.write_server_list(cache_file, {})
    if not ok then
      return {}, err
    end
  end

  local cached = M.get_enabled_servers(cache_file)

  -- Early exit if disabled
  if mode == false or mode == nil then
    return {}, nil
  end

  -- Build union depending on mode
  local final = {}
  local seen = {}

  local function add(name)
    if not seen[name] then
      seen[name] = true
      final[#final + 1] = name
    end
  end

  -- If mode is a list, add those first (or after; order doesn't matter before sort)
  if type(mode) == "table" then
    for _, name in ipairs(mode) do
      if type(name) == "string" and name ~= "" then
        add(name)
      end
    end
  end
  -- Add cached servers (for mode == true or table mode)
  for _, name in ipairs(cached) do
    if type(name) == "string" and name ~= "" then
      add(name)
    end
  end

  -- Sort for determinism
  table.sort(final)

  -- If mode was a list, persist union (only if it differs)
  if type(mode) == "table" then
    local changed = false
    if #final ~= #cached then
      changed = true
    else
      for i = 1, #final do
        if final[i] ~= cached[i] then
          changed = true
          break
        end
      end
    end
    if changed then
      local ok, werr = M.write_server_list(cache_file, final)
      if not ok then
        -- Non-fatal: we still proceed enabling
        vim.notify("[nix.lsp] " .. werr, vim.log.levels.WARN)
      end
    end
  end

  if #final == 0 then
    return {}, nil
  end

  -- Enable via Neovim API
  if vim.lsp and type(vim.lsp.enable) == "function" then
    local ok, lerr = pcall(vim.lsp.enable, final)
    if not ok then
      return {}, ("failed to enable LSP servers: %s"):format(lerr)
    end
  else
    return {}, "vim.lsp.enable is not available in this Neovim version"
  end

  return final, nil
end

return M
