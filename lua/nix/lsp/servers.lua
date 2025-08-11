local M = {}

M.configs = {
  ansiblels = {
    cmd = { 'ansible-language-server', '--stdio' },
  },
  basedpyright = {
    cmd = { 'basedpyright-langserver', '--stdio' },
    nix_package_name = 'basedpyright',
  },
  bashls = {
    cmd = { 'bash-language-server', 'start' },
  },
  clangd = {
    cmd = { 'clangd' },
    nix_package_name = 'llvmPackages_21.clang-tools',
  },
  cmake = {
    cmd = { 'cmake-language-server' },
  },
  cssls = {
    cmd = { 'vscode-css-language-server', '--stdio' },
    nix_package_name = 'vscode-langservers-extracted',
  },
  docker_language_server = {
    cmd = { 'docker-language-server', 'start', '--stdio' },
  },
  earthlyls = {
    cmd = { 'earthlyls' },
  },
  gopls = {
    cmd = { 'gopls' },
  },
  helm_ls = {
    cmd = { 'helm_ls', 'serve' },
    nix_package_name = 'helm-ls',
  },
  html = {
    cmd = { 'vscode-html-language-server', '--stdio' },
    nix_package_name = 'vscode-langservers-extracted',
  },
  jsonls = {
    cmd = { 'vscode-json-language-server', '--stdio' },
    nix_package_name = 'vscode-langservers-extracted',
  },
  lua_ls = {
    cmd = { 'lua-language-server' },
  },
  nixd = {
    cmd = { 'nixd' },
  },
  rust_analyzer = {
    cmd = { 'rust-analyzer' },
    nix_package_name = 'rustup',
  },
  ts_ls = {
    { 'typescript-language-server', '--stdio' },
  },
  yamlls = {
    cmd = { 'yaml-language-server', '--stdio' },
  },
}

M.names = vim.tbl_keys(M.configs)

function M.configure()
  for server, config in pairs(M.configs) do
    require('nix.lsp').config(server, config.cmd, config.nix_package_name)
  end
end

return M
