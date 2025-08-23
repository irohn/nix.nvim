local M = {}

---@class NixConfig
---@field data_dir string
---@field lsp NixConfigLspManager

---@class NixConfigLspManager
---@field enabled boolean|string[]  -- false/nil: disable; true: use cache; {list}: merge list with cache
---@field cache_file string         -- path to JSON file containing cached server array

---@class NixConfigNixpkgs
---@field url string
---@field allow_unfree boolean

local data_dir = string.format("%s/nix.nvim", vim.fn.stdpath("data"))

M.DEFAULT_CONFIG = {
  -- nix.nvim data directory, defaults to `stdpath("data")/nix.nvim`
  data_dir = data_dir,
  ---@type NixConfigLspManager
  -- LSP module configuration
  lsp_manager = {
    -- Enable the LSP module to automatically enable cached LSP servers.
    -- Can also be a list of servers to always enable on startup.
    -- e.g. `enabled = { "lua_ls", "pyright" }` or `enabled = true`
    enabled = false,
    -- Path to the cache file for language servers.
    -- This file will be used to store the enabled language servers.
    -- Defaults to `data_dir/language-servers.json`
    -- If the file does not exist, it will be created.
    cache_file = string.format("%s/language-servers.json", data_dir),
    -- LSP Manager UI window options
    window = {
      width = 60,
      height = 20,
      border = "rounded",
      title = " LSP Manager ",
      headers = { "", "Servers" },
      icons = {
        enabled = "⬤",
        disabled = "○",
      },
      keys = {
        close_window = { "<Esc>", "q" },
        disable_server = { "d", "x" },
        enable_server = { "i", "e" },
        show_help = { "?" },
        toggle_server = { "<Enter>" },
      }
    },
  },
  ---@type NixConfigNixpkgs
  -- nixpkgs configuration
  -- https://nixos.wiki/wiki/Nixpkgs
  nixpkgs = {
    -- The default nixpkgs url to use.
    -- Default 'nixpkgs' will use your system's default.
    -- You can use a specific branch or commit hash, e.g.:
    -- url = "github:NixOS/nixpkgs/nixos-unstable"
    -- or a specific commit hash, e.g.:
    -- url = "github:NixOS/nixpkgs/c5e2e42c112de623adfd662b3e51f0805bf9ff83
    url = "nixpkgs",
    -- Allow unfree packages
    -- https://nixos.wiki/wiki/Unfree_Software
    allow_unfree = false,
  }
}

M.config = M.DEFAULT_CONFIG

---@param opts NixConfig
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.DEFAULT_CONFIG, opts or {})
end

return M
