local M = {}

---@class NixConfig
---@field data_dir string
---@field lsp NixConfigLspManager

---@class NixConfigPluginManager
---@field enabled boolean
---@field build_dir string
---@field cache_file string
---@field plugins table
---@field settings table

---@class NixConfigLspManager
---@field enabled boolean|string[] -- false/nil: disable; true: use cache; {list}: merge list with cache
---@field cache_file string -- path to JSON file containing cached server array
---@field window table -- window configuration (see defaults below)

---@class NixConfigNixpkgs
---@field url string
---@field allow_unfree boolean

---@class NixPluginSpec
---@field pkg string
---@field src? string

local data_dir = vim.fn.stdpath("data")

M.DEFAULT_CONFIG = {
  -- nix.nvim data directory, defaults to `stdpath("data")/nix.nvim`
  data_dir = string.format("%s/nix.nvim", data_dir),
  ---@type NixConfigPluginManager
  plugin_manager = {
    -- Enable the plugin-manager module to manage plugins via nix.
    enabled = false,
    -- Directory where plugins will be built and stored.
    -- Defaults to `stdpath("data")/site/pack/nix/start`
    -- Note that if you change this, you may need to add it to your 'runtimepath'.
    build_dir = string.format("%s/site/pack/nix/start", data_dir),
    -- Path to the cache file for plugins.
    cache_file = string.format("%s/nix.nvim/plugins.json", data_dir),
    -- List of plugin specifications to manage.
    ---@type NixPluginSpec[]
    plugins = {},
    -- Plugin manager settings
    settings = {
      -- Whether to automatically scan for plugins on startup if cache is missing.
      auto_scan = true,
      -- Whether to force a rescan of plugins on startup, even if cache exists.
      -- Not recommended, as scanning can be slow and depends on network connection.
      force_rescan = false,
      -- Whether to automatically install missing plugins on startup.
      auto_install = true,
      -- Whether to show notifications for plugin operations (scan, install, etc...).
      notify = true,
    },
    window = {
      -- Window width dimension
      width = 60,
      -- Window height dimension
      height = 20,
      -- Window border style
      border = "rounded",
      -- Window title
      title = " Plugin Manager ",
      -- Header lines, these can be set to a table of strings
      -- First is the header for enabled icon, second is the server list
      -- e.g. headers = { "Status", "Servers" }
      headers = false,
      -- The icons used for enabled/disabled servers
      icons = {
        installed = "⬤",
        disabled = "○",
      },
      -- Key mappings for the plugin manager window
      keys = {
        close_window = { "<Esc>", "q" },
        remove_plugin = { "d", "x" },
        install_plugin = { "i", "e" },
        show_help = { "?" },
        toggle_plugin = { "<Enter>" },
        rescan_plugins = { "R" },
      }
    },
  },
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
    cache_file = string.format("%s/nix.nvim/language-servers.json", data_dir),
    -- LSP Manager UI window options
    window = {
      -- Window width dimension
      width = 60,
      -- Window height dimension
      height = 20,
      -- Window border style
      border = "rounded",
      -- Window title
      title = " LSP Manager ",
      -- Header lines, these can be set to a table of strings
      -- First is the header for enabled icon, second is the server list
      -- e.g. headers = { "Status", "Servers" }
      headers = false,
      -- The icons used for enabled/disabled servers
      icons = {
        enabled = "⬤",
        disabled = "○",
      },
      -- Key mappings for the LSP manager window
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
