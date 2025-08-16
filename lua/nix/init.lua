local lsp = require("nix.lsp")

local M = {}

---@param pkg string
---@param cmd? string|string[]
---@param nixpkgs? NixConfigNixpkgs
---@return string[]|nil argv  -- list of args or nil on error
---@return string? err
function M.build_nix_shell_cmd(pkg, cmd, nixpkgs)
  if type(pkg) ~= "string" or pkg == "" then
    return nil, "Package must be a non-empty string"
  end

  local cfg = nixpkgs or require("nix.config").config.nixpkgs
  cmd = cmd or pkg

  -- Base command
  local argv = {
    "nix",
    "--experimental-features", "nix-command flakes",
    "shell",
  }

  if cfg.allow_unfree then
    argv[#argv + 1] = "--impure"
  end

  argv[#argv + 1] = string.format("%s#%s", cfg.url, pkg)
  argv[#argv + 1] = "--command"

  local t = type(cmd)
  if t == "string" then
    argv[#argv + 1] = cmd
  elseif t == "table" then
    vim.list_extend(argv, cmd)
  else
    return nil, ("Invalid cmd type (%s); must be string or list of strings"):format(t)
  end

  return argv
end

---Setup function for the Nix plugin.
---
--- Behavior (opts):
--- - If `opts` is provided, it will be used to configure the plugin.
--- - If `opts` is not provided, the plugin will use its default configuration.
---
--- This function checks if Nix is installed, sets up the data directory,
--- and configures enabled features.
---
--- No return value.
---@param opts NixConfig
---@return nil
function M.setup(opts)
  if vim.fn.executable("nix") ~= 1 then
    vim.notify("Nix is not installed. Please install Nix to use this plugin.", vim.log.levels.ERROR)
    return
  end

  if opts then
    require("nix.config").setup(opts)
  end
  local config = require("nix.config").config

  vim.fn.mkdir(config.data_dir, "p")
  vim.env.NIXPKGS_ALLOW_UNFREE = config.nixpkgs.allow_unfree and 1 or 0

  if config.lsp.enabled then
    lsp.setup(config.lsp)
  end
end

return M

-- vim: ts=2 sts=2 sw=2 et
