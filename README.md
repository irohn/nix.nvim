# nix.nvim

<!-- badges: start -->
[![GitHub license](https://badgen.net/static/license/MIT/blue)](https://github.com/irohn/nix.nvim/blob/master/LICENSE)
<!-- badges: end -->

> This plugin is **very** early stages, it is still very much experimental, and breaking changes can be intorduced often. Use at your own risk!

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
This plugin is a package manager that uses [nix](https://nixos.org/) to do the heavy lifting.
You can spawn nix shells, use nix builds and search nixpkgs!
There are also complimentary LSP Manager and Plugin Manager GUIs for those who are not as comfortable with the API.

### Usage
If you just want the LSP configurations, all you need is to install the plugin, no need to call setup.
The plugin exposes a global `NixShellCmd` by default for easier command builds.
You can check the plugin is installed by running this vim command:
```lua
:lua (function() vim.cmd("enew") vim.fn.termopen(NixShellCmd("asciiquarium")) end)()
```
<img width="1081" height="546" alt="image" src="https://github.com/user-attachments/assets/54afa944-049a-46ef-b36e-eb6363c8ecab" />

### Plugin Manager
Install any plugin from [nixpkgs](https://search.nixos.org/packages?channel=unstable&query=vimPlugins), most vim plugins are prefixed with `vimPlugins.`,
theoretically, you can install any package with this though, as long as it is supported for your operating system.

To enable the Plugin Manager module:

```lua
require("nix").setup({
  plugin_manager = {
    enabled = true,
    plugins = {
      { pkg = "vimPlugins.<plugin1-name>" },
      { pkg = "vimPlugins.<plugin2-name>" }
    }
  }
})
```

You can also use the UI to install or remove plugins interactivley (this only applies to plugins installed throught nix.nvim)
for example, set a keymap to open the Plugin Manager:

```lua
vim.keymap.set("n", "<leader>P", require("nix.plugin-manager.ui").open)
```

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

You can also set a specific nixpkgs URL while building a command, the NixShellCmd global is reference to the `build_nix_shell_cmd` function:

```lua
NixShellCmd(cowsay, {"cowsay", "--version"}, { nixpkgs = { url = "github:NixOS/nixpkgs/nixos-unstable" }})
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
      -- Window width dimension
      width = 60,
      -- Window height dimension
      height = 20,
      -- Window border style
      border = "rounded",
      -- Window title
      title = " LSP Manager ",
      -- Header lines, these can be set to `false` to disable
      headers = { "", "Servers" },
      -- The icons used for enabled/disabled servers
      icons = {
        enabled = "⬤",
        disabled = "○",
      },
      -- Key mappings for the LSP manager window
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
