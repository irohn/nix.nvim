local M = {}

--- Get the binary path for a built nix package
--- @param package string The name of the package to find the binary for
--- @return string|nil The full path to the binary, or nil if not found
M.get_binary = function(package)
  local nix = require("nix")
  local data_dir = nix.options.data_dir
  local outlink = data_dir .. "/" .. package

  -- check if outlink exists
  local outlink_exists = vim.fn.isdirectory(outlink) == 1 or vim.fn.filereadable(outlink) == 1
  if not outlink_exists then
    return nil
  end

  -- check if <package>/bin/<package> exists
  local binary_path = outlink .. "/bin/" .. package
  local binary_exists = vim.fn.filereadable(binary_path) == 1 and vim.fn.executable(binary_path) == 1

  if binary_exists then
    return binary_path
  end

  return nil
end

--- Get all installed packages from the data directory
--- @return table List of package names that are installed
M.get_installed_packages = function()
  local nix = require("nix")
  local data_dir = nix.options.data_dir
  local packages = {}

  -- Check if data directory exists
  if vim.fn.isdirectory(data_dir) ~= 1 then
    return packages
  end

  -- Get all entries in the data directory
  local entries = vim.fn.readdir(data_dir)

  -- Filter for directories and symlinks (packages)
  for _, entry in ipairs(entries) do
    local full_path = data_dir .. "/" .. entry
    -- Check if it's a directory or a symlink (both indicate installed packages)
    if vim.fn.isdirectory(full_path) == 1 or vim.fn.getftype(full_path) == "link" then
      table.insert(packages, entry)
    end
  end

  return packages
end

return M
