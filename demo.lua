-- Demo script for nix.nvim LSP UI
-- Load this in Neovim: :luafile demo.lua

print("nix.nvim LSP UI Demo")
print("===================")
print()

-- Configure nix.nvim (normally done in init.lua)
require('nix').setup({
  data_dir = vim.fn.stdpath("data") .. "/nix.nvim"
})

print("Available commands:")
print("  :lua require('nix').lsp:open()    -- Open LSP manager")
print("  :lua require('nix').lsp:close()   -- Close LSP manager")
print("  :lua require('nix').lsp:toggle()  -- Toggle LSP manager")
print()

print("Keybindings in the UI:")
print("  i         -- Enable server under cursor")
print("  x         -- Disable server under cursor") 
print("  ?         -- Show help")
print("  q / <Esc> -- Close window")
print()

print("Try opening the LSP manager with:")
print("  :lua require('nix').lsp:open()")

-- Auto-open for demo
print()
print("Opening LSP manager automatically...")
require('nix').lsp:open()