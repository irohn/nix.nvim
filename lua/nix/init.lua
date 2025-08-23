local M = {}

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

  if vim.fn.has("nvim-0.11") == 0 then
    vim.notify("Nix.nvim requires Neovim 0.11 or higher.", vim.log.levels.ERROR)
    return
  end

  if opts then
    require("nix.config").setup(opts)
  end
  local config = require("nix.config").config

  vim.fn.mkdir(config.data_dir, "p")
  vim.env.NIXPKGS_ALLOW_UNFREE = config.nixpkgs.allow_unfree and 1 or 0

  if config.plugin_manager.enabled then
    require("nix.plugin-manager").setup(config.plugin_manager)
  end

  if config.lsp_manager.enabled then
    require("nix.lsp-manager").setup(config.lsp_manager)
  end
end

return M

-- vim: ts=2 sts=2 sw=2 et
