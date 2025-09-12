local config = require("nix.config")
local util = require("nix.util")

local M = {}

function M.setup(opts)
  config.setup(opts)
  local options = config.options

  -- create directories if they don't exist
  util.ensure_directories({
    options.data_dir,
    options.nix.outlink_dir
  })

  -- Load plugin manager if enabled
  if options.plugin_manager.enabled then
    vim.api.nvim_command("packadd nix-plugin-manager")
    require("nix-plugin-manager").setup()
  end

  -- Load LSP manager if enabled
  if options.lsp_manager.enabled then
    vim.api.nvim_command("packadd nix-lsp-manager")
    require("nix-lsp-manager").setup()
  end

  -- Load user commands
  require("nix.commands").setup()
end

function M.run(pkgs, args, use_first_pkg_as_first_arg)
  use_first_pkg_as_first_arg = use_first_pkg_as_first_arg or true
  assert(pkgs, "Package name is required")
  if type(pkgs) == "string" then pkgs = { pkgs } end
  if use_first_pkg_as_first_arg then
    args = args or {}
    table.insert(args, 1, pkgs[1])
  end
  local shell = require("nix.lib.shell"):new({ packages = pkgs })
  local cmd = shell:generate_command(args or {})
  local out = vim.system(cmd):wait()
  return out.stdout
end

return M
