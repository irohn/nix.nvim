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
  ensure_in_store = {},

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
  <summary><a href="https://github.com/neovim/nvim-lspconfig">nvim-lspconfig</a> and <a href="https://github.com/stevearc/conform.nvim">conform.nvim</a></summary>

This example integrates lsp and autocompletion.
You can put this directly in your `init.lua` or require it from a file.
The important thing is to run this code **after** you installed the plugins

```lua
local nix = require("nix")

local conform_setup = { formatters = {}, formatters_by_ft = {} }
local enabled_servers = {}

local function find_nix_path(bin)
	local package_info = nix.package_info(bin)
	if package_info then
		if package_info.binaries and #package_info.binaries == 1 then
			return package_info.binaries[1]
		else
			local cmd = { "fd", "--type", "f", "--glob", bin, package_info.dir }
			local result = vim.system(cmd, { text = true }):wait()
			if result.code == 0 and result.stdout and result.stdout ~= "" then
				local paths = vim.split(vim.trim(result.stdout), "\n")
				if #paths > 0 then
					return paths[1]
				end
			end
			-- Fallback to find
			cmd = { "find", package_info.dir, "-type", "f", "-name", bin }
			result = vim.system(cmd, { text = true }):wait()
			if result.code == 0 and result.stdout and result.stdout ~= "" then
				local paths = vim.split(vim.trim(result.stdout), "\n")
				if #paths > 0 then
					return paths[1]
				end
			end
			return package_info.dir .. "/result/bin/" .. bin
		end
	end
	return bin
end

local filetypes = {
	lua = {
		language_server = {
			lua_ls = {
				bin = "lua-language-server",
				config = {
					on_init = function(client)
						if client.workspace_folders then
							local path = client.workspace_folders[1].name
							if
								path ~= vim.fn.stdpath("config")
								and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
							then
								return
							end
						end

						client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
							runtime = {
								version = "LuaJIT",
								path = {
									"lua/?.lua",
									"lua/?/init.lua",
								},
							},
							-- Make the server aware of Neovim runtime files
							workspace = {
								checkThirdParty = false,
								library = {
									vim.env.VIMRUNTIME,
									"${3rd}/luv/library",
									"${3rd}/busted/library",
									vim.fn.stdpath("data") .. "/lazy",
								},
							},
						})
					end,
					settings = {
						Lua = {},
					},
				},
			},
		},
		formatters = {
			stylua = {
				command = "stylua",
			},
		},
	},
}

for ft in pairs(filetypes) do
	if filetypes[ft].language_server then
		for server, opts in pairs(filetypes[ft].language_server) do
			local bin = find_nix_path(opts.bin or server)
			local config = opts.config or {}
			config["cmd"] = { bin }
			vim.lsp.config(server, config)
			table.insert(enabled_servers, server)
		end
	end

	-- conform
	if filetypes[ft].formatters then
		conform_setup.formatters_by_ft[ft] = vim.tbl_keys(filetypes[ft].formatters)
	end

	for formatter, config in pairs(filetypes[ft].formatters or {}) do
		local bin = find_nix_path(config.bin or formatter)
		local cmd = { bin }
		conform_setup.formatters[formatter] = { command = cmd[1] }
	end
end

vim.lsp.enable(enabled_servers)
require("conform").setup(conform_setup)

-- vim: ts=2 sts=2 sw=2 et

```

</details>

## TODO

- [x] Add integration with Conform
- [x] Add integration with builtin LSP / lspconfig
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
