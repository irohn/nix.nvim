local args = { 'basedpyright-langserver', '--stdio' }
local pkg = 'basedpyright'

require('nix.lsp').config('basedpyright', pkg, args)
