# nix.nvim

A Neovim plugin that provides seamless integration with the Nix package manager, allowing you to install, manage, and use Nix packages directly from within Neovim.

## Features

- **Package Management**: Install, list, and remove Nix packages with simple commands
- **Multiple Output Support**: Handles packages with multiple outputs (bin, doc, man) correctly
- **Ensure Installed**: Automatically install specified packages on startup
- **Health Check**: Built-in health check to verify Nix installation and configuration
- **Flakes Support**: Full support for Nix flakes (experimental feature)
- **Metadata Tracking**: Tracks installed packages and their outputs for reliable management
- **Command Aliases**: Convenient aliases for common operations
- **Auto-completion**: Tab completion for commands and package names

## Requirements

- **Neovim** 0.7.0 or later
- **Nix** package manager installed and configured
- **Operating System**: Linux or macOS (Windows not supported)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "your-username/nix.nvim",
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
  "your-username/nix.nvim",
  config = function()
    require("nix").setup()
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'your-username/nix.nvim'

lua << EOF
require("nix").setup()
EOF
```

## Configuration

The plugin comes with sensible defaults, but you can customize it:

```lua
require("nix").setup({
  -- Data directory for storing packages (defaults to stdpath("data")/nix.nvim)
  data_dir = vim.fn.stdpath("data") .. "/nix.nvim",
  
  -- Packages to automatically install on startup
  ensure_installed = {
    "hello",
    "shellcheck", 
    "nixpkgs-fmt",
  },
  
  -- Experimental features
  experimental_feature = {
    -- Enable Nix flakes support (default: true)
    flakes = true,
  },
  
  -- Nixpkgs configuration
  nixpkgs = {
    -- Nixpkgs URL/channel to use (default: "nixpkgs")
    url = "nixpkgs",
    -- For latest nixpkgs:
    -- url = "https://github.com/NixOS/nixpkgs/archive/master.tar.gz"
  },
})
```

## Usage

### Commands

All commands are available through the `:Nix` command with various subcommands:

#### Install Packages

```vim
:Nix install <package_name>
:Nix i <package_name>          " Alias for install
```

If no package name is provided, you'll be prompted to enter one.

#### List Installed Packages

```vim
:Nix list
:Nix ls                        " Alias for list
:Nix inspect                   " Alias for list
```

Shows an interactive list of installed packages with details.

#### Remove Packages

```vim
:Nix remove <package_name>
:Nix rm <package_name>         " Alias for remove
:Nix delete <package_name>     " Alias for remove
```

If no package name is provided, you'll get an interactive selection menu.

#### Garbage Collection

```vim
:Nix garbage-collect
:Nix gc                        " Alias for garbage-collect
```

Runs Nix garbage collection to clean up unused packages.

#### Help

```vim
:Nix help                      " Show general help
:Nix help <subcommand>         " Show help for specific subcommand
```

### Programmatic API

You can also use the plugin programmatically in your Lua configuration:

```lua
local nix = require("nix")

-- Get package information
local package_info = nix.package("shellcheck")
if package_info then
  print("Package dir: " .. package_info.dir)
  print("Binaries: " .. table.concat(package_info.binaries, ", "))
  print("Store path: " .. package_info.store_path)
end

-- Install a package programmatically
local success, err = nix.build("hello")
if not success then
  print("Failed to install: " .. err)
end
```

## Health Check

Run the health check to verify your Nix installation:

```vim
:checkhealth nix
```

This will verify:
- Operating system compatibility
- Nix installation and version
- Nix flakes support
- Plugin configuration

## How It Works

### Package Installation
- Uses `nix build` (or `nix-build` for legacy) to install packages
- Creates symlinks in the plugin's data directory
- Tracks package metadata including all outputs (bin, doc, man, etc.)
- Supports packages with multiple outputs correctly

### Package Management
- Maintains metadata files to track what was installed
- Handles cleanup of all package outputs when removing
- Provides fallback support for packages installed before metadata tracking

### Directory Structure
```
~/.local/share/nvim/nix.nvim/
├── packages/           # Symlinks to installed packages
│   ├── shellcheck-bin  # Binary output
│   ├── shellcheck-doc  # Documentation output
│   └── shellcheck-man  # Manual pages output
└── metadata/           # Package tracking information
    └── shellcheck.json # Metadata for shellcheck package
```
## TODO
- [] Create a GUI for interacting with nix.nvim
- [] Redirect common LSPs cmd to the nix store instead of using PATH
- [] Add option to allow the use of nix-env (low priority)

## Troubleshooting

### Nix Not Found
If you get "Nix is not installed" error:
1. Install Nix from https://nixos.org/download/
2. Ensure `nix` is in your PATH
3. Run `:checkhealth nix` to verify installation

### Flakes Not Working
If flakes-related commands fail:
1. Enable experimental features in your Nix configuration
2. Add to `~/.config/nix/nix.conf`:
   ```
   experimental-features = nix-command flakes
   ```

### Permission Issues
If you encounter permission errors:
1. Ensure your user has permission to use Nix
2. Check that the data directory is writable
3. Verify Nix daemon is running (if using multi-user installation)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

