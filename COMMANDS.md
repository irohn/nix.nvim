# Nix.nvim - Extensible User Commands

The Nix user command system provides a cobra-like subcommand structure that's easily extensible.

## Built-in Commands

The following commands are available out of the box:

- `:Nix build <package>` - Build a nix package (e.g., `:Nix build pyright`)
- `:Nix delete <package>` - Delete a built package  
- `:Nix gc` - Run garbage collection to clean up unused packages
- `:Nix list` - List installed packages
- `:Nix help [subcommand]` - Show help for all commands or a specific subcommand

## Usage Examples

```vim
" Build the pyright language server
:Nix build pyright

" List all installed packages
:Nix list

" Get help for the build command
:Nix help build

" Show all available commands
:Nix help
```

## Adding New Subcommands

The system is designed to be easily extensible. To add a new subcommand, use the `register_subcommand` function:

```lua
local user_commands = require("nix.api.user_commands")

-- Register a new subcommand
user_commands.register_subcommand({
  name = "install",
  desc = "Install a package system-wide",
  args = {
    {name = "package", required = true, desc = "Package name to install"},
    {name = "profile", required = false, desc = "Profile to install to"}
  },
  handler = function(args, opts)
    local package = args[1]
    local profile = args[2] or "default"
    -- Your implementation here
    print("Installing " .. package .. " to profile " .. profile)
  end,
  complete = function(args, cmd_line, cursor_pos)
    -- Return completion candidates
    if #args == 0 then
      return {"nodejs", "python3", "git"} -- Example package names
    elseif #args == 1 then
      return {"default", "dev", "testing"} -- Example profile names
    end
    return {}
  end
})
```

## Features

- **Argument validation**: Automatically validates required arguments
- **Help system**: Built-in help generation for all subcommands
- **Tab completion**: Smart completion for subcommands and their arguments
- **Error handling**: Clear error messages for invalid usage
- **Extensible**: Easy to add new subcommands without modifying core code

## Architecture

The system consists of:

1. **Subcommand Registry**: A central registry that stores all available subcommands
2. **Command Dispatcher**: Routes commands to their appropriate handlers
3. **Argument Parser**: Parses and validates command arguments
4. **Completion Engine**: Provides intelligent tab completion
5. **Help System**: Generates help text for commands

This design makes it easy to add new functionality while maintaining a consistent user experience.

## Health Check

The plugin includes comprehensive health checks to ensure proper setup and functionality. Run the health check with:

```vim
:checkhealth nix
```

The health check verifies:
- **Neovim version**: Ensures you're running Neovim 0.11.0 or newer (required)
- **Nix command**: Checks if the `nix` command is available in your PATH (required)
- **Nix features**: Detects if experimental features like flakes are enabled
- **Plugin configuration**: Validates that the plugin configuration loads correctly
- **Plugin commands**: Ensures the Nix user command is properly registered
- **Runtime dependencies**: Checks that required Neovim features are available
- **Nix store**: Verifies access to the Nix store (optional but recommended)

If any critical checks fail, the health check will provide clear instructions on how to fix the issues.

