local M = {}

M.servers = {
  basedpyright = {
    cmd = { 'basedpyright-langserver', '--stdio' },
    nix_package_name = 'basedpyright',
  },
  lua_ls = {
    cmd = { 'lua-language-server' },
    nix_package_name = 'lua-language-server',
  },
}

M.servers_names = vim.tbl_keys(M.servers)

function M.configure()
  for server, config in pairs(M.servers) do
    require("nix.lsp").config(server, config.nix_package_name, config.cmd)
  end
end

return M
