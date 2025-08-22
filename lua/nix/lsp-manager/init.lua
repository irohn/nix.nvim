local M = {}

local config = require("nix.config").config.lsp_manager
M.cache_file = config.cache_file

local function read_lines(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return nil, ("failed to read cache file '%s': %s"):format(path, lines)
  end
  return lines
end

local function decode_server_list(text)
  local path = M.cache_file
  if text == "" then
    return {}
  end
  local ok, decoded = pcall(vim.fn.json_decode, text)
  if not ok or type(decoded) ~= "table" then
    vim.notify(
      ("[lsp-manager] Invalid JSON in cache '%s'; ignoring and resetting: %s")
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

function M.get_runtime_lsp_server_names(force_rescan)
  force_rescan = force_rescan or false
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

function M.get_enabled_servers()
  -- Read existing cached servers
  local lines, rerr = read_lines(M.cache_file)
  if not lines then
    return {}, rerr
  end
  local cached = decode_server_list(table.concat(lines, "\n"))
  return cached
end

function M.write_server_list(servers)
  local path = M.cache_file
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

function M.enable_servers(servers)
  if type(servers) ~= "table" then
    vim.notify("Expected a table of servers to enable", vim.log.levels.ERROR)
    return false, "Invalid servers table"
  end

  local enabled_servers = M.get_enabled_servers()

  for _, server in ipairs(servers) do
    -- Only call vim.lsp.enable if available (might not be in headless mode)
    if vim.lsp and vim.lsp.enable then
      vim.lsp.enable(server, true)
    end
    if not vim.tbl_contains(enabled_servers, server) then
      table.insert(enabled_servers, server)
    end
  end
  local changed, err = M.write_server_list(enabled_servers)
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

  local enabled_servers = M.get_enabled_servers()
  for _, server in ipairs(servers) do
    -- Only call vim.lsp.enable if available (might not be in headless mode)
    if vim.lsp and vim.lsp.enable then
      vim.lsp.enable(server, false)
    end
    enabled_servers = vim.tbl_filter(function(s)
      return s ~= server
    end, enabled_servers)
  end

  local changed, err = M.write_server_list(enabled_servers)
  if not changed then
    vim.notify("Failed to write to data file: " .. (err or ""), vim.log.levels.ERROR)
  end

  return changed, err
end

function M.setup()
  -- Ensure cache file exists (create empty array if missing)
  if vim.fn.filereadable(M.cache_file) == 0 then
    local ok, err = M.write_server_list({})
    if not ok then
      return {}, err
    end
  end

  local cached = M.get_enabled_servers()

  local final = {}
  for _, name in ipairs(cached) do
    final[#final + 1] = name
  end

  table.sort(final)

  if #final == 0 then
    return
  end

  vim.lsp.enable(final)
end

return M
