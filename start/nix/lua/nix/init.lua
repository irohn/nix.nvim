local config = require("nix.config")

local M = {}

function M.setup(opts)
  config.setup(opts)
  local options = config.options

  -- create data directory if it doesn't exist
  if vim.fn.isdirectory(options.data_dir) == 0 then
    vim.fn.mkdir(options.data_dir, "p")
  end

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
end

return M
