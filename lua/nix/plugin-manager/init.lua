local M = {}

---Setup function for the nix plugin-manager module.
---@param opts NixConfigPluginManager
---@return nil
function M.setup(opts)
  local build_dir = opts.build_dir
  vim.fn.mkdir(build_dir, "p")

  ---@type NixPluginSpec[]
  local plugins = opts.plugins
end

return M
