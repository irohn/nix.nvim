# nix.nvim

A Neovim plugin that provides seamless integration with the Nix package manager, allowing you to install, manage, and use Nix packages directly from within Neovim.

> This plugin is very experimental and still in active development, use at your own risk!

## Features

- **Package Management**: Install, list, and remove Nix packages with simple commands
- **Multiple Output Support**: Handles packages with multiple outputs (bin, doc, man) correctly
- **Ensure Installed**: Automatically install specified packages on startup
- **Health Check**: Built-in health check to verify Nix installation and configuration
- **Flakes Support**: Full support for Nix flakes (experimental feature)
- **Command Aliases**: Convenient aliases for common operations
- **Auto-completion**: Tab completion for commands and package names

## Requirements

- **Neovim** 0.7.0 or later
- **Nix** package manager installed and configured
- **Operating System**: Linux or macOS (Windows not supported)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)
<details open>
  <summary>Code</summary>

```lua
{
  "irohn/nix.nvim",
  config = function()
    require("nix").setup({
      -- Configuration options (see below)
    })
  end,
}
```
</details>

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)
<details open>
  <summary>Code</summary>

```lua
use {
  "irohn/nix.nvim",
  config = function()
    require("nix").setup()
  end
}
```
</details>

### Using [vim-plug](https://github.com/junegunn/vim-plug)
<details open>
  <summary>Code</summary>

```vim
Plug 'irohn/nix.nvim'

lua << EOF
require("nix").setup()
EOF
```
</details>

## Configuration

The plugin comes with sensible defaults, but you can customize it:

```lua
{
  -- Data directory for storing packages (defaults to stdpath("data")/nix.nvim)
  data_dir = vim.fn.stdpath("data") .. "/nix.nvim",
  
  -- Packages to automatically install on startup
  ensure_installed = {},
  
  -- Experimental features
  experimental_feature = {
    -- Enable Nix flakes support (default: true)
    flakes = false,
  },
  
  -- Nixpkgs configuration
  nixpkgs = {
    -- Nixpkgs URL/channel to use (default: "nixpkgs" = system channel / flake input)
    url = "nixpkgs",
    -- For latest nixpkgs:
    -- url = "https://github.com/NixOS/nixpkgs/archive/master.tar.gz"
  },
}
```

## Usage

### Commands

All commands are available through the `:Nix` command with various subcommands:

#### Install Packages

```vim
:Nix install <package_name>
:Nix i <package_name>          " Alias for install
:Nix list
:Nix ls                        " Alias for list
:Nix inspect                   " Alias for list
:Nix remove <package_name>
:Nix rm <package_name>         " Alias for remove
:Nix delete <package_name>     " Alias for remove
:Nix garbage-collect
:Nix gc                        " Alias for garbage-collect
:Nix help                      " Show general help
:Nix help <subcommand>         " Show help for specific subcommand
```

## Integration with other plugins

<details>
  <summary>[conform.nvim](https://github.com/stevearc/conform.nvim)</summary>

```lua
local get_cmd = function(cmd)
	return function()
		if vim.fn.executable(cmd) == 1 then return cmd end
		local ok, nix = pcall(require, "nix")
		return ok and nix.package(cmd) and (nix.package(cmd).binaries[1] or nix.package(cmd).dir .. "/result/bin/" .. cmd) or cmd
	end
end

return {
	{
		"stevearc/conform.nvim",
		opts = {
			formatters = { stylua = { command = get_cmd("stylua") } },
			formatters_by_ft = { lua = { "stylua" } }
		},
	},
}
```
</details>

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

## TODO
- [ ] Create a GUI for interacting with nix.nvim
- [ ] Add an option to allow the use of nix-env / nix profile (add packages to PATH)
- [ ] Take advantage of existing nix files in directories (for project specific dependencies)
- [ ] Add packages metadata (idk what its useful for yet but it probably will be)
- [ ] Add nix repl buffer / command (maybe?)

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
3. See the [flakes](https://wiki.nixos.org/wiki/Flakes) wiki for more information.

### Permission Issues
If you encounter permission errors:
1. Ensure your user has permission to use Nix
2. Check that the data directory is writable
3. Verify Nix daemon is running (if using multi-user installation)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

