local M = {}

-- Setup cached LSP servers.
---@return nil
---@param opts NixConfig.lsp
function M.setup(opts)
  local ensure_enabled = opts.enabled
  local cache_file = opts.cache_file

  if vim.fn.filereadable(cache_file) == 0 then
    vim.fn.writefile({ "[]" }, cache_file)
  end

  local servers = {}
  servers = vim.fn.json_decode(vim.fn.readfile(cache_file))

  if type(ensure_enabled) == "table" then
    vim.tbl_extend("force", ensure_enabled, servers)
  end

  if #servers > 0 then
    vim.lsp.enable(servers)
  end
end

return M
