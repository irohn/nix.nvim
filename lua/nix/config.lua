local M = {}

---@class NixConfig
local DEFAULT_CONFIG = {
  -- nix.nvim data directory, defaults to `stdpath("data")/nix.nvim`
  ---@type string
  data_dir = string.format("%s/nix.nvim", vim.fn.stdpath("data")),

  -- Experimental features configuration
  ---@type table<string, boolean>
  experimental_feature = {
    -- Enable Nix flakes support
    --
    -- Setting this to true will use 'nix-command' and 'flakes'
    -- and will run commands like `nix build` instead `nix-build`
    ---@type boolean
    flakes = true
  },

  -- Nixpkgs instance configuration
  ---@type table
  nixpkgs = {
    -- The nixpkgs instance used to download packages
    -- The default 'nixpkgs' will use your system's instance
    --
    -- For example, build packages from the latest version of nixpkgs
    -- ```lua
    --   nixpkgs = {
    --     url = "https://github.com/NixOS/nixpkgs/archive/master.tar.gz"
    --   }
    -- ```
    ---@type string
    url = "nixpkgs"
  }
}

M._DEFAULT_CONFIG = DEFAULT_CONFIG
M.current = M._DEFAULT_CONFIG

---@param opts NixConfig
function M.set(opts)
  M.current = vim.tbl_deep_extend("force", M.current, opts)
end

return M
