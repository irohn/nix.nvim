--- @class nixnvimConfig
--- @field data_dir string The directory where nix packages will be stored (default: vim.fn.stdpath("data") .. "/nix")
--- @field nixpkgs_url string Enable a specific nixpkgs instance (default: nixpkgs - the system channel)
--- @field experimental_features nixnvimExperimentalFeatures Configuration for experimental nix features

--- @class nixnvimExperimentalFeatures
--- @field flakes boolean Enable nix flakes support (default: false)

local default_options = {
  data_dir = vim.fn.stdpath("data") .. "/nix",
  nixpkgs_url = "nixpkgs",
  experimental_features = {
    flakes = false
  }
}

local M = {}

--- @type nixnvimConfig
M.options = vim.deepcopy(default_options)

--- Setup nix.nvim with the provided configuration
--- @param opts nixnvimConfig|nil Configuration options for nix.nvim
function M.setup(opts)
  -- Deep-merge user opts into default_options, and store in M.options
  M.options = vim.tbl_deep_extend('force', vim.deepcopy(default_options), opts or {})

  -- Ensure data directory exists
  vim.fn.mkdir(M.options.data_dir, "p")
end

return M

-- vim: ts=2 sts=2 sw=2 et
