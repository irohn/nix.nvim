local M = {}

-- Helper function to check if a command exists
local function command_exists(cmd)
  return vim.fn.executable(cmd) == 1
end

-- Helper function to get command version
local function get_command_version(cmd, version_flag)
  version_flag = version_flag or "--version"
  local result = vim.fn.system(cmd .. " " .. version_flag)
  if vim.v.shell_error == 0 then
    return vim.trim(result)
  end
  return nil
end

-- Helper function to parse version string and compare with minimum requirement
local function version_meets_requirement(version_str, min_version)
  if not version_str then
    return false
  end

  -- Extract version number from string (handles formats like "NVIM v0.11.0" or "nix (Nix) 2.18.1")
  local version = version_str:match("(%d+%.%d+%.%d+)")
  if not version then
    return false
  end

  local function version_to_number(v)
    local major, minor, patch = v:match("(%d+)%.(%d+)%.(%d+)")
    return tonumber(major) * 10000 + tonumber(minor) * 100 + tonumber(patch)
  end

  return version_to_number(version) >= version_to_number(min_version)
end

-- Check Neovim version requirement
local function check_neovim_version()
  vim.health.start("Neovim version")

  local nvim_version = vim.version()
  local version_str = string.format("%d.%d.%d", nvim_version.major, nvim_version.minor, nvim_version.patch)
  local min_required = "0.11.0"

  if version_meets_requirement(version_str, min_required) then
    vim.health.ok(string.format("Neovim %s (>= %s required)", version_str, min_required))
  else
    vim.health.error(
      string.format("Neovim %s is too old (>= %s required)", version_str, min_required),
      "Please upgrade Neovim to version 0.11.0 or newer"
    )
  end
end

-- Check Nix command availability
local function check_nix_command()
  vim.health.start("Nix command")

  if command_exists("nix") then
    local version = get_command_version("nix", "--version")
    if version then
      vim.health.ok(string.format("nix command found: %s", version:gsub("\n", " ")))
    else
      vim.health.ok("nix command found (version check failed)")
    end
  else
    vim.health.error(
      "nix command not found in PATH",
      {
        "Install Nix package manager: https://nixos.org/download.html",
        "Make sure 'nix' command is available in your PATH",
        "You may need to restart your terminal or source your shell profile"
      }
    )
  end
end

-- Check Nix experimental features (flakes, nix-command)
local function check_nix_features()
  vim.health.start("Nix experimental features")

  if not command_exists("nix") then
    vim.health.warn("Cannot check Nix features - nix command not available")
    return
  end

  -- Test if nix flakes work
  local flakes_result = vim.fn.system("nix flake --help 2>/dev/null")
  if vim.v.shell_error == 0 then
    vim.health.ok("Nix flakes support detected")
  else
    vim.health.warn(
      "Nix flakes not available",
      {
        "Consider enabling experimental features: nix-command flakes",
        "Add to ~/.config/nix/nix.conf: experimental-features = nix-command flakes",
        "Or use --experimental-features flag with nix commands"
      }
    )
  end
end

-- Check plugin configuration
local function check_plugin_config()
  vim.health.start("Plugin configuration")

  local ok, config = pcall(require, "nix.config")
  if not ok then
    vim.health.error("Failed to load nix.config module: " .. config)
    return
  end

  vim.health.ok("Plugin configuration loaded successfully")

  -- Check if the plugin has been set up
  if vim.g.nix_nvim_setup_called then
    vim.health.ok("Plugin setup() has been called")
  else
    vim.health.warn(
      "Plugin setup() has not been called explicitly",
      "Consider calling require('nix').setup() in your config for explicit initialization"
    )
  end
end

-- Check plugin commands
local function check_plugin_commands()
  vim.health.start("Plugin commands")

  -- Check if Nix user command exists
  local commands = vim.api.nvim_get_commands({})
  if commands.Nix then
    vim.health.ok("Nix user command is registered")
  else
    vim.health.error(
      "Nix user command not found",
      "Make sure the plugin is properly loaded and setup() has been called"
    )
  end

  -- Check if core modules can be loaded
  local modules_to_check = {
    "nix.api.commands",
    "nix.api.user_commands",
    "nix.api.utils",
    "nix.notify"
  }

  local failed_modules = {}
  for _, module in ipairs(modules_to_check) do
    local ok, err = pcall(require, module)
    if not ok then
      table.insert(failed_modules, module .. ": " .. err)
    end
  end

  if #failed_modules == 0 then
    vim.health.ok("All core plugin modules loaded successfully")
  else
    vim.health.error(
      "Failed to load some plugin modules",
      failed_modules
    )
  end
end

-- Check runtime dependencies
local function check_runtime_dependencies()
  vim.health.start("Runtime dependencies")

  -- Check if required Vim features are available
  local required_features = {
    { "User commands", function() return vim.api.nvim_create_user_command ~= nil end },
    { "Lua >= 5.1",    function() return _VERSION ~= nil end },
    { "vim.health",    function() return vim.health ~= nil end },
    { "vim.notify",    function() return vim.notify ~= nil end },
  }

  for _, feature in ipairs(required_features) do
    local name, check_fn = feature[1], feature[2]
    if check_fn() then
      vim.health.ok(name .. " available")
    else
      vim.health.error(name .. " not available")
    end
  end
end

-- Check Nix store permissions (optional)
local function check_nix_store()
  vim.health.start("Nix store")

  if not command_exists("nix") then
    vim.health.warn("Cannot check Nix store - nix command not available")
    return
  end

  -- Check if nix-store command works
  local store_result = vim.fn.system("nix-store --version 2>/dev/null")
  if vim.v.shell_error == 0 then
    vim.health.ok("Nix store accessible")
  else
    vim.health.warn(
      "Nix store may not be accessible",
      "Some plugin features may not work properly"
    )
  end

  -- Check if we can query the store
  local query_result = vim.fn.system("nix-store -q --references /nix/store 2>/dev/null | head -1")
  if vim.v.shell_error == 0 and query_result ~= "" then
    vim.health.ok("Nix store query operations work")
  else
    vim.health.warn("Nix store query operations may be limited")
  end
end

-- Main health check function
function M.check()
  check_neovim_version()
  check_nix_command()
  check_nix_features()
  check_plugin_config()
  check_plugin_commands()
  check_runtime_dependencies()
  check_nix_store()
end

return M

-- vim: ts=2 sts=2 sw=2 et
