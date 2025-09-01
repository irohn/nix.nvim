local M = {}

function M.setup(opts)
  opts = opts or {}

  -- Expose command to open LSP manager UI
  vim.api.nvim_create_user_command("NixLspManager", function()
    require("nix.view").open_lsp_manager()
  end, { desc = "Open Nix LSP Manager UI" })

  local ok, reg = pcall(require, "nix-lsp-manager.lib.registry")
  if ok then
    reg.bootstrap()
  end
end

return M
