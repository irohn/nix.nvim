local M = {}

M.command = function(pkg, args)
  local cmd = {
    'nix',
    '--experimental-features',
    'nix-command flakes',
    'shell',
    'nixpkgs#' .. pkg,
    '--command'
  }
  if #args > 0 then
    for _, arg in ipairs(args) do
      table.insert(cmd, arg)
    end
  else
    vim.notify('No arguments provided for nix command', vim.log.levels.WARN)
  end
  return cmd
end

---@param opts NixConfig | nil
M.setup = function(opts)
  if vim.fn.executable('nix') ~= 1 then
    vim.notify('Nix is not installed. Please install Nix to use this plugin.', vim.log.levels.ERROR)
    return
  end

  if opts then
    require("nix.config").setup(opts)
  end
  local config = require("nix.config").config

  vim.fn.mkdir(config.data_dir, 'p')

  if config.lsp.enabled then
    local data_file = config.data_dir .. '/language-servers.json'
    require("nix.lsp").load(data_file)
  end
end

return M

-- vim: ts=2 sts=2 sw=2 et
