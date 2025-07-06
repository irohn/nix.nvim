local config = require("nix.config")
local user_commands = require("nix.api.user_commands")

local M = {}

---@param opts NixConfig | nil
function M.setup(opts)
  if opts then
    config.set(opts)
  end

  -- Mark that setup has been called explicitly
  vim.g.nix_nvim_setup_called = true

  -- Initialize user commands
  user_commands.setup()
end

return M

-- vim: ts=2 sts=2 sw=2 et
