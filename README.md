# nix.nvim

<!-- badges: start -->
[![GitHub license](https://badgen.net/static/license/MIT/blue)](https://github.com/irohn/nix.nvim/blob/master/LICENSE)
<!-- badges: end -->

> This plugin is **very** early stages, it is still very much experimental, breaking changes can occur often. Use at your own risk!

Use the power of nix to run applications without installing them!
<img width="936" height="182" alt="image" src="https://github.com/user-attachments/assets/3fb2fc00-0507-4d76-ad6f-f83ab4c7599f" />

- [Requirements](#requirements)
- [Installation](#installation)
- [Information](#information)
- [Usage](#usage)
- [Plugin Manager](#plugin-manager)
- [LSP Manager](#lsp-manager)
- [Nixpkgs](#nixpkgs)
- [Configuration](#configuration)

## Requirements
- nvim 0.11+
- [nix](https://nixos.org/download/) (tested on version 2.30+)

## Installation
<details open>
<summary>Pack</summary>
<br>

Add the following into your init.lua

```lua
local target = vim.fn.stdpath("data") .. "/site/pack/nix.nvim"
if not (vim.uv or vim.loop).fs_stat(target) then
  local repo = "https://github.com/irohn/nix.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=refactor", repo, target })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone nix.nvim:\n", "ErrorMsg" },
      { out,                           "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(target)
```

</details>

## Information
This plugin is a package manager that uses [nix](https://nixos.org/) to do the heavy lifting.
You can spawn nix shells, use nix builds and search nixpkgs!
There are also complimentary LSP Manager and Plugin Manager GUIs for those who are not as comfortable with the API.

## Usage

### Plugin Manager
Install any plugin from [nixpkgs](https://search.nixos.org/packages?channel=unstable&query=vimPlugins), most vim plugins are prefixed with `vimPlugins.`,
theoretically, you can install any package with this though, as long as it is supported for your operating system.

To enable the Plugin Manager module:

```lua
require("nix").setup({
  plugin_manager = {
    enabled = true,
    plugins = {
      { name = "oil-nvim", config = function()
        require("oil").setup()
      end},
    }
  }
})

-- keymap to open the Plugin Manager UI
vim.keymap.set("n", "<leader>P", "<cmd>NixPluginManager<cr>", { noremap = true, silent = true })
```

You can also use the UI to install or remove plugins interactivley (this only applies to plugins installed throught nix.nvim)
<img width="816" height="643" alt="image" src="https://github.com/user-attachments/assets/9d5e9bcb-3880-472c-8f1a-e7896dea2498" />

### LSP Manager
A simple UI for enabling / disabling LSP servers, press `?` in the LSP Manager for keybindings.
<img width="703" height="475" alt="image" src="https://github.com/user-attachments/assets/8f6e0588-9562-4976-a4c2-00fed91f4db2" />

To use the LSP Manager module, you can enable it in your configuration:

```lua
require("nix").setup({
  lsp_manager = {
    enabled = true
    -- You can also pass a table to enable servers on startup:
    -- enabled = {
      -- "lua_ls",
      -- "bashls",
      -- "rust_analyzer"
    -- }
  }
})

vim.keymap.set("n", "<leader>L", "<cmd>NixLspManager<cr>", { noremap = true, silent = true })
```

### Nixpkgs
By default this plugin uses your system's nixpkgs channel.
You can change the nixpkgs version using a URL for example, to use the unstable channel and allow unfree packages:

```lua
require("nix").setup {
  nix = {
    nixpkgs = "github:NixOS/nixpkgs/nixos-unstable",
  }
}
```

### Configuration
This is the default configuration (no need to call setup if you use the defaults):
```lua
{
  data_dir = vim.fn.stdpath("data") .. "/nix",
  nix = {
    command = { "nix", "--experimental-features", "nix-command flakes" },
    nixpkgs = "nixpkgs",
    allow_unfree = false,
    outlink_dir = vim.fn.stdpath("data") .. "/site/pack/nix/opt",
  },
  plugin_manager = {
    enabled = true,
    plugins = {},
    window = {
      width = 0.6,
      height = 0.6,
      border = "rounded",
      title = "Plugin Manager",
      icons = {
        checked = "◼",
        unchecked = "◻",
      },
      keys = {
        check = { "i" },
        uncheck = { "u" },
        toggle = { "<CR>" },
        sort = { "s" },
        help = { "?" },
        close = { "q", "<Esc>" },
      }
    }
  },
  lsp_manager = {
    enabled = false,
    servers = {},
    window = {
      width = 0.6,
      height = 0.6,
      border = "rounded",
      title = "LSP Manager",
      icons = {
        checked = "◼",
        unchecked = "◻",
      },
      keys = {
        check = { "i" },
        uncheck = { "u" },
        toggle = { "<CR>" },
        sort = { "s" },
        help = { "?" },
        close = { "q", "<Esc>" },
      }
    }
  },
}
```
