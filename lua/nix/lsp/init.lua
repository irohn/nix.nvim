local command = require('nix').command

local M = {}

-- Construct the command for the LSP server configuration
M.config = function(lsp_name, pkg, args)
  if not lsp_name or not pkg then
    vim.notify('LSP name and package name must be provided', vim.log.levels.ERROR)
    return
  end

  local cmd = command(pkg, args or {})
  vim.lsp.config(lsp_name, {
    cmd = cmd
  })
end

-- Enable the given LSP server
M.enable = function(lsp_name)
  if not lsp_name then
    vim.notify('LSP name must be provided to enable LSP', vim.log.levels.ERROR)
    return
  end

  if not vim.lsp.is_enabled(lsp_name) then
    vim.lsp.enable(lsp_name, false)
  end
  vim.lsp.enable(lsp_name, true)
end

-- Load or restart LSP servers from the data_file
M.load = function(data_file)
  if vim.fn.filereadable(data_file) == 0 then
    vim.fn.writefile({ '[]' }, data_file)
  end

  local servers = vim.fn.json_decode(vim.fn.readfile(data_file))
  if #servers > 0 then
    for _, server in ipairs(servers) do
      M.enable(server)
    end
  end
end

return M
