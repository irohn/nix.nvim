local defaults = require("nix.config")._DEFAULT_CONFIG

local M = {}

--- Get all installed packages from the data directory
--- @return table List of package names that are installed
M.get_installed_packages = function(data_dir)
  data_dir = data_dir or defaults.data_dir
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
