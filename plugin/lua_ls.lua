local args = { 'lua-language-server' }
local pkg = args[1]

require('nix.lsp').config('lua_ls', pkg, args)
