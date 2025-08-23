---@type NixConfigNixpkgs
local nixpkgs = require("nix.config").config.nixpkgs

local M = {}

---Builds a nix search command to find packages matching a pattern with optional configuration.
---@param pattern string
---@param opts? NixConfigNixpkgs
---@return table argv  -- list of args empty on error
function M.build_command(pattern, opts)
  opts = vim.tbl_deep_extend("force", nixpkgs, opts or {})

  -- Ensure pattern is a non-empty string
  if type(pattern) ~= "string" or pattern == "" then
    return {}
  end

  local cmd = {
    "nix",
    "--experimental-features",
    "nix-command flakes",
    "search",
  }

  if opts.allow_unfree then
    table.insert(cmd, "--impure")
  end

  table.insert(cmd, opts.url)
  table.insert(cmd, pattern)

  return cmd
end

return M
