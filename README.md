# nix.nvim

A Neovim plugin that provides seamless integration with the Nix package manager, allowing you to install, manage, and use Nix packages directly from within Neovim.

> This plugin is very experimental and still in active development, use at your own risk!

## Requirements

- **Neovim** 0.7.0 or later
- **Nix** package manager installed and configured
- **Operating System**: Linux or macOS (Windows not supported)

## Installation

<details open>
  <summary><a href="https://github.com/folke/lazy.nvim">lazy.nvim</a> (recommended)</summary>

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

<details>
  <summary><a href="https://github.com/wbthomason/packer.nvim">packer.nvim</a></summary>

```lua
use {
  "irohn/nix.nvim",
  config = function()
    require("nix").setup()
  end
}
```
</details>

<details>
  <summary><a href="https://github.com/junegunn/vim-plug">vim-plug</a></summary>

```vim
Plug 'irohn/nix.nvim'

lua << EOF
require("nix").setup()
EOF
```
</details>

It is recommended to run `:checkhealth nix` after installation

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

All commands are available through the `:Nix` command with various subcommands:

```vim
:Nix install <package_name>    " Install a package from nixpkgs
:Nix i <package_name>          " Alias for install
:Nix list                      " List all installed packages
:Nix ls                        " Alias for list
:Nix inspect                   " Alias for list
:Nix remove <package_name>     " Remove an installed package
:Nix rm <package_name>         " Alias for remove
:Nix delete <package_name>     " Alias for remove
:Nix garbage-collect           " Clean up unused packages and free disk space
:Nix gc                        " Alias for garbage-collect
:Nix help                      " Show general help
:Nix help <subcommand>         " Show help for specific subcommand
```

## Integration with other plugins

<details>
  <summary><a href="https://github.com/stevearc/conform.nvim">conform.nvim</a></summary>

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

