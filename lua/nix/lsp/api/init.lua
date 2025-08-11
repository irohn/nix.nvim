local data_file = require('nix.config').config.data_dir .. '/language-servers.json'

local M = {}

-- Get enabled language servers from the data file.
---@return string[]
function M.get_enabled_servers()
  local content = table.concat(vim.fn.readfile(data_file), "\n")
  return vim.json.decode(content) or {}
end

-- Get all servers available from 'nix.lsp.servers.servers'.
-- This does not check if the server is enabled or not.
---@return string[]
function M.get_all_servers()
  local servers = require("nix.lsp.servers").names
  return servers
end

-- Write the given servers to the data file.
-- This will overwrite the existing content of the file.
---@param servers table<string> A table of server names to write to the data file.
---@return boolean changed, string? err
function M.write_to_data_file(servers)
  if type(servers) ~= 'table' then
    vim.notify('Expected a table of servers to write to data file', vim.log.levels.ERROR)
    return false, 'Invalid servers table'
  end

  local content = vim.json.encode(servers)
  vim.fn.writefile({ content }, data_file, 'b')
  return true
end

-- Enable a list of servers and write them to the data file.
-- This will merge the existing servers with the new ones.
---@param servers table<string> A table of server names to enable.
---@return boolean changed, string? err
function M.enable_servers(servers)
  if type(servers) ~= 'table' then
    vim.notify('Expected a table of servers to enable', vim.log.levels.ERROR)
    return false, 'Invalid servers table'
  end

  local enabled_servers = M.get_enabled_servers()
  for _, server in ipairs(servers) do
    vim.lsp.enable(server, true)
    if not vim.tbl_contains(enabled_servers, server) then
      table.insert(enabled_servers, server)
    end
  end

  local changed, err = M.write_to_data_file(enabled_servers)
  if not changed then
    vim.notify('Failed to write to data file: ' .. (err or ''), vim.log.levels.ERROR)
  end

  return changed, err
end

-- Disable a list of servers and remove them from the data file.
---@param servers table<string> A table of server names to disable.
---@return boolean changed, string? err
function M.disable_servers(servers)
  if type(servers) ~= 'table' then
    vim.notify('Expected a table of servers to disable', vim.log.levels.ERROR)
    return false, 'Invalid servers table'
  end

  local enabled_servers = M.get_enabled_servers()
  for _, server in ipairs(servers) do
    vim.lsp.enable(server, false)
    enabled_servers = vim.tbl_filter(function(s) return s ~= server end, enabled_servers)
  end

  local changed, err = M.write_to_data_file(enabled_servers)
  if not changed then
    vim.notify('Failed to write to data file: ' .. (err or ''), vim.log.levels.ERROR)
  end

  return changed, err
end

return M
