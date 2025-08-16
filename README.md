# nix.nvim

<!-- badges: start -->
[![GitHub license](https://badgen.net/static/license/MIT/blue)](https://github.com/irohn/nix.nvim/blob/master/LICENSE)
<!-- badges: end -->

Use the power of nix to run applications without installing them!
<img width="1870" height="797" alt="image" src="https://github.com/user-attachments/assets/bcf87204-68ce-458c-a6f2-0d004b2600e3" />

### Requirements
- nvim 0.12+
- [nix](https://nixos.org/download/) (tested on version 2.30+)

### Installation
<details open>
<summary>vim.pack</summary>
<br>
  
```lua
vim.pack.add({
  { src = "https://github.com/irohn/nix.nvim" },
})
```

</details>

<details>
<summary> <a href="https://lazy.folke.io/">lazy.nvim</a> </summary>
<br>
  
```lua
{
  "irohn/nix.nvim",
  lazy = false
}
```

</details>

### What is this plugin?
First, this is a collection of lsp configurations that modifies the `cmd` attribute to use a nix shell instead of directly calling the binary for the LSP.
As a result, this plugin gives you an API to generate a nix command to run binaries, for example, say you are creating a plugin that needs the app `cowsay` to run, you could generate a shell command that anyone can call as long as they have nix installed:

```lua
local cowsay = require("nix").build_nix_shell_cmd("cowsay")

local on_exit = function(obj)
  print(obj.code)
  print(obj.signal)
  print(obj.stdout)
  print(obj.stderr)
end

vim.system(cowsay, { text = true }, on_exit)
```

### Usage
As a standalone, this plugin only needs to be installed, if you only want to use the LSP servers defined in this repo and you already have a working configuration, you don't need to call the setup function.
Here are the defaults:

```lua
require("nix").setup {
  -- nix.nvim data directory, defaults to `stdpath("data")/nix.nvim`
  data_dir = string.format("%s/nix.nvim", vim.fn.stdpath("data")),
  ---@type NixConfigLsp
  -- LSP module configuration
  lsp = {
    -- Enable the LSP module to automatically enable cached LSP servers.
    -- Can also be a list of servers to always enable on startup.
    -- e.g. `enabled = { "lua_ls", "pyright" }` or `enabled = true`
    enabled = false,
    -- Path to the cache file for language servers.
    -- This file will be used to store the enabled language servers.
    -- Defaults to `data_dir/language-servers.json`
    -- If the file does not exist, it will be created.
    cache_file = string.format("%s/nix.nvim/language-servers.json", vim.fn.stdpath("data")),
  },
  ---@type NixConfigNixpkgs
  -- nixpkgs configuration
  -- https://nixos.wiki/wiki/Nixpkgs
  nixpkgs = {
    -- The default nixpkgs url to use.
    -- Default 'nixpkgs' will use your system's default.
    -- You can use a specific branch or commit hash, e.g.:
    -- url = "github:NixOS/nixpkgs/nixos-unstable"
    -- or a specific commit hash, e.g.:
    -- url = "github:NixOS/nixpkgs/c5e2e42c112de623adfd662b3e51f0805bf9ff83
    url = "nixpkgs",

    -- Allow unfree packages
    -- https://nixos.wiki/wiki/Unfree_Software
    allow_unfree = false,
  }
}
```

### LSP Manager
I added a simple LSP Manager so you can enable/disable servers easily, note that this works on all lsp servers you have configured via the ./lsp directory in any runtime path. This works best with a plugin like [lspconfig](https://github.com/neovim/nvim-lspconfig) that adds default servers to your configuration. the ./lsp directory in this repo will overwrite the `cmd` field for each configured LSP, however if you already have the LSP installed and it is not in this repository, you can still enable it! use the `:checkhealth lsp` to make sure you have the binary installed.
If you want to enable the LSP Manager module you will need to specificly enable it, here is how I do it in my config:

```lua
require("nix").setup({
  lsp = {
    enabled = true,
  },
})

vim.keymap.set("n", "<leader>l", require("nix").lsp.toggle)
```

Use the `?` key in the LSP Manager buffer to see the keybindgs

### Nixpkgs
By default this plugin uses your system's nixpkgs channel, and does not allow unfree packages.
You can change the nixpkgs version using a URL for example, to use the unstable channel:

```lua
require("nix").setup {
  nixpkgs = { url = "github:NixOS/nixpkgs/nixos-unstable" }
}
```
