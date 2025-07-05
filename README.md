# nix.nvim

A Neovim plugin for seamless Nix package management within your editor. Build, manage, and use Nix packages directly from Neovim with full support for both traditional Nix and Nix Flakes.

> NOTE:
>   This plugin is extremley experimental, use at your own risk!

## Features

- 🚀 **Build Nix packages** directly from Neovim
- 🗑️ **Delete package symlinks** from your data directory
- 🧹 **Garbage collection** with nix-store --gc integration
- 📦 **Package discovery** - list all installed packages
- 🔍 **Binary path resolution** - find executable paths for built packages
- ⚡ **Flakes support** - experimental Nix flakes integration
- 📊 **Async operations** - non-blocking package builds and operations

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "irohns/nix.nvim", -- Replace with your actual repository
  config = function()
    require("nix").setup({
      -- Configuration options (see below)
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "irohns/nix.nvim", -- Replace with your actual repository
  config = function()
    require("nix").setup()
  end
}
```

## Configuration

The plugin comes with sensible defaults but can be fully customized:

```lua
require("nix").setup({
  -- Directory where nix packages will be stored as symlinks
  data_dir = vim.fn.stdpath("data") .. "/nix",
  
  -- Nixpkgs source to use for package builds
  nixpkgs_url = "nixpkgs", -- Uses system channel by default
  
  -- Experimental features
  experimental_features = {
    flakes = false, -- Enable Nix flakes support
  }
})
```

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `data_dir` | `string` | `vim.fn.stdpath("data") .. "/nix"` | Directory where built packages are symlinked |
| `nixpkgs_url` | `string` | `"nixpkgs"` | Nixpkgs source (channel, URL, or flake reference) |
| `experimental_features.flakes` | `boolean` | `false` | Enable Nix flakes support |

## API Reference

### Commands Module

#### `require("nix.commands").build(package)`

Build a Nix package and create a symlink in the data directory.

**Parameters:**
- `package` (string): Name of the package to build from nixpkgs

**Example:**
```lua
require("nix.commands").build("ripgrep")
```

#### `require("nix.commands").delete(package)`

Remove a package symlink from the data directory.

**Parameters:**
- `package` (string): Name of the package to delete

**Example:**
```lua
require("nix.commands").delete("ripgrep")
```

#### `require("nix.commands").gc()`

Run garbage collection to clean up unused Nix store paths. Shows a confirmation dialog before proceeding.

**Example:**
```lua
require("nix.commands").gc()
```

### Utility Module

#### `require("nix.util").get_binary(package)`

Get the binary path for a built Nix package.

**Parameters:**
- `package` (string): Name of the package

**Returns:**
- `string|nil`: Full path to the binary, or nil if not found

**Example:**
```lua
local binary_path = require("nix.util").get_binary("ripgrep")
if binary_path then
  print("ripgrep is available at: " .. binary_path)
end
```

#### `require("nix.util").get_installed_packages()`

Get a list of all installed packages.

**Returns:**
- `table`: Array of package names (strings)

**Example:**
```lua
local packages = require("nix.util").get_installed_packages()
for _, package in ipairs(packages) do
  print("Installed: " .. package)
end
```

## Usage Examples

### Basic Package Management

```lua
-- Build a package
require("nix.commands").build("fd")

-- Check if it's available
local fd_path = require("nix.util").get_binary("fd")
if fd_path then
  print("fd is available at: " .. fd_path)
end

-- List all installed packages
local packages = require("nix.util").get_installed_packages()
print("Installed packages:", vim.inspect(packages))

-- Clean up a package
require("nix.commands").delete("fd")
```

### Using with Flakes

```lua
require("nix").setup({
  experimental_features = {
    flakes = true
  },
  nixpkgs_url = "github:NixOS/nixpkgs/nixos-unstable"
})

-- Now builds will use flakes syntax
require("nix.commands").build("ripgrep")
```

### Integration with Telescope

Create a custom picker to manage your Nix packages:

```lua
local function nix_packages_picker()
  local packages = require("nix.util").get_installed_packages()
  
  require("telescope.pickers").new({}, {
    prompt_title = "Nix Packages",
    finder = require("telescope.finders").new_table({
      results = packages
    }),
    actions = {
      ["<CR>"] = function(prompt_bufnr)
        local selection = require("telescope.actions.state").get_selected_entry()
        require("telescope.actions").close(prompt_bufnr)
        
        local binary_path = require("nix.util").get_binary(selection.value)
        if binary_path then
          print("Binary path: " .. binary_path)
        end
      end,
      ["<C-d>"] = function(prompt_bufnr)
        local selection = require("telescope.actions.state").get_selected_entry()
        require("nix.commands").delete(selection.value)
        -- Refresh the picker
      end
    }
  }):find()
end

-- Create a command for it
vim.api.nvim_create_user_command("NixPackages", nix_packages_picker, {})
```

## How It Works

1. **Package Building**: Uses `nix-build` (traditional) or `nix build` (flakes) to build packages
2. **Symlink Management**: Creates symlinks in your configured data directory pointing to Nix store paths
3. **Binary Resolution**: Looks for executables in `<package>/bin/<package>` pattern
4. **Garbage Collection**: Integrates with `nix-store --gc` for cleanup

## Directory Structure

```
data_dir/
├── package1/  -> /nix/store/...-package1/
├── package2/  -> /nix/store/...-package2/
└── ...
```

Each directory in your data_dir is a symlink to the actual package in the Nix store.

## Requirements

- Neovim >= 0.11.0
- Nix package manager installed and available in PATH
- For flakes support: Nix with flakes experimental feature enabled

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

