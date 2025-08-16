local lsp = require("nix.lsp")
local config = require("nix.config").config

local M = {}

-- UI methods - delegate to the UI module (loaded lazily to avoid circular dependencies)
function M.open()
  require("nix.lsp.ui").open()
end

function M.close()
  require("nix.lsp.ui").close()
end

function M.toggle()
  require("nix.lsp.ui").toggle()
end

-- Get enabled language servers from the cache file.
---@return string[]
function M.get_enabled_servers()
  return lsp.get_enabled_servers(config.lsp.cache_file)
end

-- Get all servers available from runtime LSP server names.
-- This uses the runtime path scanning to find available servers.
---@return string[]
function M.get_all_servers()
  return lsp.get_runtime_lsp_server_names()
end

-- Write the given servers to the cache file.
-- This will overwrite the existing content of the file.
---@param servers table<string> A table of server names to write to the cache file.
---@return boolean changed, string? err
function M.write_to_data_file(servers)
  return lsp.write_server_list(config.lsp.cache_file, servers)
end

-- Enable a list of servers and write them to the cache file.
-- This will merge the existing servers with the new ones.
---@param servers table<string> A table of server names to enable.
---@return boolean changed, string? err
function M.enable_servers(servers)
  return lsp.enable_servers(servers)
end

-- Disable a list of servers and remove them from the cache file.
---@param servers table<string> A table of server names to disable.
---@return boolean changed, string? err
function M.disable_servers(servers)
  return lsp.disable_servers(servers)
end

return M