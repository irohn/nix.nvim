local nix = require("nix.config").options.nix
local base_command = nix.command
local nixpkgs = nix.nixpkgs
local outlink_dir = nix.outlink_dir

---
--- NixPackage class for managing Nix packages via Neovim
---
---@class NixPackage
---@field name string Package name
---@field nixpkgs? string Nixpkgs flake reference
---@field outlink? string Output link path
local M = {}
M.__index = M

---
--- Create a new NixPackage instance
---
---@param opts table|string Options table or package name string
--- opts = {
---   name = string Package name (required)
---   nixpkgs = string? Nixpkgs flake reference (optional)
---   outlink = string? Output link path (optional)
--- }
---@return NixPackage
function M:new(opts)
  self = setmetatable({}, M)

  if type(opts) == "string" then
    opts = { name = opts }
  else
    opts = opts or {}
  end
  assert(opts.name, "Package name is required")

  self.name = opts.name
  self.nixpkgs = opts.nixpkgs or nixpkgs
  self.outlink = opts.outlink or (outlink_dir .. "/" .. self.name)

  return self
end

function M:__toString()
  return string.format("NixPackage(name=%s, nixpkgs=%s, outlink=%s)", self.name, self.nixpkgs, self.outlink)
end

M.__tostring = M.__toString

---
--- Build the Nix package into a directory, verifying with a dry-run first
---
---@class BuildOptions
---@field outlink string? Output link directory
---@field cmd_opts table? Options for vim.system
---@field on_exit fun(obj: table)? Callback for process exit
---@param opts BuildOptions? Options table
--- opts = {
---   outlink = string? Output link directory (optional)
---   cmd_opts = table? Options for vim.system (optional)
---   on_exit = fun(obj: table)? Callback for process exit (optional)
--- }
function M:build(opts)
  opts = opts or {}
  local cmd = vim.deepcopy(base_command)
  opts.cmd_opts = opts.cmd_opts or { text = true }
  opts.on_exit = opts.on_exit or function(obj)
    if obj.code == 0 then
      vim.schedule(function()
        vim.notify(string.format("Package %s built successfully!", self.name), vim.log.levels.INFO)
      end)
    else
      vim.schedule(function()
        vim.notify(string.format("Failed to build package %s.", self.name), vim.log.levels.ERROR)
      end)
    end
  end

  -- check if outlink exists on filesystem, if it does, skip build
  -- outlinks are symlinks, we need to handle that
  local stat = vim.loop.fs_stat(self.outlink)
  if stat then
    if stat.type == "link" then
      local target = vim.loop.fs_readlink(self.outlink)
      if target and vim.fn.isdirectory(target) == 1 then
        return
      end
    end
  end

  -- Prepare dry-run command
  local dry_cmd = vim.deepcopy(cmd)
  table.insert(dry_cmd, "build")
  table.insert(dry_cmd, "--dry-run")
  table.insert(dry_cmd, string.format("%s#%s", self.nixpkgs, self.name))
  table.insert(dry_cmd, "--out-link")
  table.insert(dry_cmd, string.format("%s", self.outlink))

  -- Run dry-run first
  vim.system(dry_cmd, opts.cmd_opts, function(dry_obj)
    if dry_obj.code == 0 then
      -- Dry run succeeded, run actual build
      local build_cmd = vim.deepcopy(cmd)
      table.insert(build_cmd, "build")
      table.insert(build_cmd, string.format("%s#%s", self.nixpkgs, self.name))
      table.insert(build_cmd, "--out-link")
      table.insert(build_cmd, string.format("%s", self.outlink))
      vim.system(build_cmd, opts.cmd_opts, opts.on_exit)
    else
      -- Dry run failed, notify and do not run build
      vim.schedule(function()
        vim.notify(string.format("Dry run failed for package %s. Build not attempted.", self.name), vim.log.levels.ERROR)
      end)
    end
  end)
end

---
--- Remove the installed Nix package
---
---@return boolean removed True if removed, false otherwise
function M:remove()
  local stat = vim.loop.fs_stat(self.outlink)
  if not stat then
    vim.notify(string.format("Package %s is not installed.", self.name), vim.log.levels.WARN)
    return false
  end
  if stat.type == "link" then
    local target = vim.loop.fs_readlink(self.outlink)
    if not target or vim.fn.isdirectory(target) == 0 then
      vim.notify(string.format("Symlink for package %s is broken or target directory does not exist.", self.name),
        vim.log.levels.WARN)
      return false
    end
  elseif stat.type ~= "directory" then
    vim.notify(string.format("Package %s path exists but is not a directory.", self.name), vim.log.levels.WARN)
    return false
  end

  local removed = vim.fn.delete(self.outlink, "rf") == 0
  if not removed then
    vim.notify(string.format("Failed to remove package %s.", self.name), vim.log.levels.ERROR)
  else
    vim.notify(string.format("Package %s removed successfully.", self.name), vim.log.levels.INFO)
  end

  return removed
end

---
--- Update the Nix package (remove then build)
---
---@param opts table? Options table
function M:update(opts)
  opts = opts or {}
  self:remove()
  self:build(opts)
end

function M:export()
  return {
    name = self.name,
    nixpkgs = self.nixpkgs,
    outlink = self.outlink,
  }
end

return M
