# nix.nvim

<!-- badges: start -->
[![GitHub license](https://badgen.net/static/license/MIT/blue)](https://github.com/irohn/nix.nvim/blob/master/LICENSE)
<!-- badges: end -->

Use the power of nix to run applications without installing them!
<img width="936" height="182" alt="image" src="https://github.com/user-attachments/assets/3fb2fc00-0507-4d76-ad6f-f83ab4c7599f" />

- [Requirements](#requirements)
- [Installation](#installation)
- [Information](#information)
- [Usage](#usage)
- [LSP Manager](#lsp-manager)
- [Nixpkgs](#nixpkgs)
- [Configuration](#configuration)

### Requirements
- nvim 0.11+
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

### Information
This is an API to expose nix shells in neovim, this lets you build commands you can run as long as you have nix installed.
You can configure where you pull packages from, see the [Nixpkgs](#nixpkgs) section for more info.
It is also an LSP config collection taken from [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) modified to use the nix instead of PATH.
Note that some LSPs are missing, this is because I couldn't find them in [nixpkgs](https://github.com/NixOS/nixpkgs) or the configuration did not use a standard `cmd` field.
There is an LSP Manager module as well, but it is disabled by default, see the [LSP Manager](#lsp-manager) section for more info.

### Usage
If you just want the LSP configurations, all you need is to install the plugin, no need to call setup.
The plugin exposes a global `NixCmd` by default for easier command builds.
You can check the plugin is installed by running this vim command:
```lua
:lua (function() vim.cmd("enew") vim.fn.termopen(NixCmd("asciiquarium")) end)()
```
<img width="1081" height="546" alt="image" src="https://github.com/user-attachments/assets/54afa944-049a-46ef-b36e-eb6363c8ecab" />

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

-- To open the LSP Manager window you can call `require("nix.lsp-manager.ui").open()`
-- there are also `close()` and `toggle()` functions, to set a keymap for this:
vim.keymap.set("n", "<leader>lsp", require("nix.lsp-manager.ui").toggle, { desc = "Toggle LSP Manager" })
```

### Nixpkgs
By default this plugin uses your system's nixpkgs channel, and does not allow unfree packages.
You can change the nixpkgs version using a URL for example, to use the unstable channel and allow unfree packages:

```lua
require("nix").setup {
  nixpkgs = {
    url = "github:NixOS/nixpkgs/nixos-unstable",
    allow_unfree = true
  }
}
```

You can also set a specific nixpkgs URL while building a command, the NixCmd global is reference to the `build_nix_shell_cmd` function:

```lua
NixCmd(cowsay, {"cowsay", "--version"}, { nixpkgs = { url = "github:NixOS/nixpkgs/nixos-unstable" }})
```

### Configuration
This is the default configuration (no need to call setup if you use the defaults):
```lua
{
  -- nix.nvim data directory, defaults to `stdpath("data")/nix.nvim`
  data_dir = data_dir,
  ---@type NixConfigLspManager
  -- LSP module configuration
  lsp_manager = {
    -- Enable the LSP module to automatically enable cached LSP servers.
    -- Can also be a list of servers to always enable on startup.
    -- e.g. `enabled = { "lua_ls", "pyright" }` or `enabled = true`
    enabled = false,
    -- Path to the cache file for language servers.
    -- This file will be used to store the enabled language servers.
    -- Defaults to `data_dir/language-servers.json`
    -- If the file does not exist, it will be created.
    cache_file = string.format("%s/language-servers.json", data_dir),
    -- LSP Manager UI window options
    window = {
      width = 60,
      height = 20,
      border = "rounded",
      title = " LSP Manager ",
      headers = { "", "Servers" },
      icons = {
        enabled = "⬤",
        disabled = "○",
      },
      keys = {
        close_window = { "<Esc>", "q" },
        disable_server = { "d", "x" },
        enable_server = { "i", "e" },
        show_help = { "?" },
        toggle_server = { "<Enter>" },
      }
    },
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
