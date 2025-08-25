---@type NixConfigNixpkgs
local nixpkgs = require("nix.config").config.nixpkgs

local M = {}

---Builds a nix shell command to run a package with optional arguments and configuration.
---@param package string
---@param args? string|string[]
---@param opts? NixConfigNixpkgs
---@return table argv  -- list of args empty on error
function M.build_command(package, args, opts)
  opts = vim.tbl_deep_extend("force", nixpkgs, opts or {})

  -- Ensure package is a non-empty string
  if type(package) ~= "string" or package == "" then
    return {}
  end

  -- Default args to package if not provided
  if not args then
    args = package
  end

  -- Ensure args is a string or a list of strings
  if type(args) ~= "string" and type(args) ~= "table" then
    return {}
  end

  local cmd = {
    "nix",
    "--experimental-features",
    "nix-command flakes",
    "shell",
  }

  if opts.allow_unfree then
    table.insert(cmd, "--impure")
  end

  table.insert(cmd, string.format("%s#%s", opts.url, package))
  table.insert(cmd, "--command")
  if type(args) == "string" then
    table.insert(cmd, args)
  else
    vim.list_extend(cmd, args)
  end

  return cmd
end

return M
