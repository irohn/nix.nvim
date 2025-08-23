---@type NixConfigNixpkgs
local nixpkgs = require("nix.config").config.nixpkgs

local M = {}

---Builds a nix build command to build a package with optional configuration.
---@param package string
---@param outlink? string
---@param opts? NixConfigNixpkgs
function M.build_command(package, outlink, opts)
  opts = vim.tbl_deep_extend("force", nixpkgs, opts or {})

  -- Ensure package is a non-empty string
  if type(package) ~= "string" or package == "" then
    return {}
  end

  -- Set outlink to package name if not provided
  if not outlink or type(outlink) ~= "string" or outlink == ""
  then
    outlink = package
  end

  local cmd = {
    "nix",
    "--experimental-features",
    "nix-command flakes",
    "build",
  }

  if opts.allow_unfree then
    table.insert(cmd, "--impure")
  end

  table.insert(cmd, string.format("%s#%s", opts.url, package))
  table.insert(cmd, "--out-link")
  table.insert(cmd, outlink)

  return cmd
end

return M
