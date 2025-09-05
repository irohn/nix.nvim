local plugins_handler = require("nix-plugin-manager.handlers.plugins")

local M = {}

M.registry = require("nix-plugin-manager.lib.registry")

function M.setup()
  plugins_handler.scan_plugins(false, function(success)
    if success then
      vim.schedule(function()
        M.registry.bootstrap()

        -- Expose command to open Plugin manager UI
        vim.api.nvim_create_user_command("NixPluginManager", function()
          require("nix.view").open_plugin_manager()
        end, { desc = "Open Nix Plugin Manager UI" })
      end)
    end
  end)
end

return M
