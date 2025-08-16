local lsp = require("nix.lsp")

local M = {}

---@param package string
---@param cmd? string|table<string>
---@param nixpkgs? NixConfig.nixpkgs
---@return table<string>
function M.cmd(package, cmd, nixpkgs)
  if not package then
    vim.notify("Package must be specified", vim.log.levels.ERROR)
    return {}
  end
  cmd = cmd or package
  nixpkgs = nixpkgs or require("nix.config").config.nixpkgs

  local command = {}
  table.insert(command, "nix")
  table.insert(command, "--experimental-features")
  table.insert(command, "nix-command flakes")
  table.insert(command, "shell")
  if nixpkgs.allow_unfree then
    table.insert(command, "--impure")
  end
  table.insert(command, string.format("%s#%s", nixpkgs.url, package))
  table.insert(command, "--command")
  if type(cmd) == "string" then
    table.insert(command, cmd)
  elseif type(cmd) == "table" then
    for _, c in ipairs(cmd) do
      table.insert(command, c)
    end
  else
    vim.notify(
      string.format("Invalid cmd type for package '%s': %s", package, vim.inspect(cmd)),
      vim.log.levels.ERROR
    )
    return {}
  end

  return command
end

---@param opts NixConfig | nil
---@return nil
--- Setup function for the Nix plugin.
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
