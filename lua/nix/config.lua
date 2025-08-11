local M = {}

---@class NixConfig
M.DEFAULT_CONFIG = {
  ---@type string
  -- nix.nvim data directory, defaults to `stdpath("data")/nix.nvim`
  data_dir = string.format("%s/nix.nvim", vim.fn.stdpath("data")),

  ---@type table
  -- LSP module configuration
  lsp = {
    ---@type boolean
    -- Enable the LSP modlue to automatically load LSP servers
    enabled = true,
  },
}

M.config = M.DEFAULT_CONFIG

---@param opts NixConfig
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.DEFAULT_CONFIG, opts or {})
end

return M
