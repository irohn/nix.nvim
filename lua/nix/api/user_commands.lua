local commands = require("nix.api.commands")
local utils = require("nix.api.utils")
local notify = require("nix.notify")

local M = {}

-- Subcommand registry
local subcommands = {}

---@class SubcommandSpec
---@field name string The name of the subcommand
---@field desc string Description of the subcommand
---@field handler function The function to handle the subcommand
---@field args? table Argument specification
---@field complete? function Custom completion function

--- Register a new subcommand
---@param spec SubcommandSpec
function M.register_subcommand(spec)
  subcommands[spec.name] = spec
end

--- Get completion candidates for subcommands and their arguments
---@param cmd_line string The current command line
---@param cursor_pos integer The cursor position
---@return table List of completion candidates
local function complete_nix_command(cmd_line, cursor_pos)
  local args = vim.split(cmd_line, "%s+")

  -- Remove "Nix" from args
  if args[1] == "Nix" then
    table.remove(args, 1)
  end

  -- If we're at the first argument (subcommand), complete subcommand names
  if #args == 0 or (#args == 1 and not cmd_line:match("%s$")) then
    local candidates = {}
    for name, spec in pairs(subcommands) do
      table.insert(candidates, name)
    end
    table.sort(candidates)
    return candidates
  end

  -- If we have a subcommand, delegate to its completion function
  local subcommand_name = args[1]
  local subcommand = subcommands[subcommand_name]

  if subcommand and subcommand.complete then
    -- Remove the subcommand name from args for the completion function
    local sub_args = {}
    for i = 2, #args do
      table.insert(sub_args, args[i])
    end
    return subcommand.complete(sub_args, cmd_line, cursor_pos)
  end

  return {}
end

--- Show help for a specific subcommand or general help
---@param subcommand_name? string The subcommand to show help for
local function show_help(subcommand_name)
  if subcommand_name and subcommands[subcommand_name] then
    local spec = subcommands[subcommand_name]
    local help_text = string.format("Nix %s - %s", spec.name, spec.desc)

    if spec.args then
      help_text = help_text .. "\n\nUsage: Nix " .. spec.name
      for _, arg in ipairs(spec.args) do
        if arg.required then
          help_text = help_text .. " <" .. arg.name .. ">"
        else
          help_text = help_text .. " [" .. arg.name .. "]"
        end
      end

      help_text = help_text .. "\n\nArguments:"
      for _, arg in ipairs(spec.args) do
        help_text = help_text .. string.format("\n  %s: %s", arg.name, arg.desc or "")
      end
    end

    notify(help_text)
  else
    -- Show general help
    local help_text = "Nix - Nix package manager integration\n\nAvailable subcommands:"

    local sorted_commands = {}
    for name, spec in pairs(subcommands) do
      table.insert(sorted_commands, { name = name, desc = spec.desc })
    end
    table.sort(sorted_commands, function(a, b) return a.name < b.name end)

    for _, cmd in ipairs(sorted_commands) do
      help_text = help_text .. string.format("\n  %-12s %s", cmd.name, cmd.desc)
    end

    help_text = help_text .. "\n\nUse 'Nix help <subcommand>' for more information about a subcommand."
    notify(help_text)
  end
end

--- Main command handler
---@param opts table Command options from vim.api.nvim_create_user_command
local function nix_command_handler(opts)
  local args = vim.split(opts.args, "%s+")

  -- Remove empty strings
  args = vim.tbl_filter(function(arg) return arg ~= "" end, args)

  if #args == 0 then
    show_help()
    return
  end

  local subcommand_name = args[1]

  -- Handle help command specially
  if subcommand_name == "help" then
    show_help(args[2])
    return
  end

  local subcommand = subcommands[subcommand_name]
  if not subcommand then
    notify(string.format("Unknown subcommand: %s\nUse 'Nix help' to see available subcommands.", subcommand_name),
      vim.log.levels.ERROR)
    return
  end

  -- Extract arguments for the subcommand (excluding the subcommand name itself)
  local subcommand_args = {}
  for i = 2, #args do
    table.insert(subcommand_args, args[i])
  end

  -- Validate arguments if spec is provided
  if subcommand.args then
    local required_count = 0
    for _, arg_spec in ipairs(subcommand.args) do
      if arg_spec.required then
        required_count = required_count + 1
      end
    end

    if #subcommand_args < required_count then
      local missing_args = {}
      for i = #subcommand_args + 1, required_count do
        table.insert(missing_args, subcommand.args[i].name)
      end
      notify(string.format("Missing required arguments for '%s': %s\nUse 'Nix help %s' for usage information.",
        subcommand_name, table.concat(missing_args, ", "), subcommand_name), vim.log.levels.ERROR)
      return
    end
  end

  -- Call the subcommand handler
  subcommand.handler(subcommand_args, opts)
end

--- Initialize the Nix user command
function M.setup()
  -- Register built-in subcommands
  M.register_subcommand({
    name = "build",
    desc = "Build a nix package",
    args = {
      { name = "package", required = false, desc = "Package name to build" }
    },
    handler = function(args)
      if #args == 0 then
        vim.ui.input({
          prompt = "Enter package name to build: ",
        }, function(input)
          if input and input ~= "" then
            commands.build(input)
          end
        end)
      else
        commands.build(args[1])
      end
    end,
    complete = function(args)
      -- TODO: Could implement package name completion from nixpkgs
      return {}
    end
  })

  M.register_subcommand({
    name = "delete",
    desc = "Delete a built package",
    args = {
      { name = "package", required = false, desc = "Package name to delete" }
    },
    handler = function(args)
      if #args == 0 then
        local packages = utils.get_installed_packages()
        if #packages == 0 then
          notify("No packages installed")
          return
        end
        vim.ui.select(packages, {
          prompt = "Select package to delete:",
          format_item = function(item)
            return item
          end
        }, function(choice)
          if choice then
            commands.delete(choice)
          end
        end)
      else
        commands.delete(args[1])
      end
    end,
    complete = function(args)
      -- Complete with installed package names
      if #args == 0 then
        return utils.get_installed_packages()
      end
      return {}
    end
  })

  M.register_subcommand({
    name = "gc",
    desc = "Run garbage collection to clean up unused packages",
    handler = function(args)
      commands.gc()
    end
  })

  M.register_subcommand({
    name = "list",
    desc = "List installed packages",
    handler = function(args)
      local packages = utils.get_installed_packages()
      if #packages == 0 then
        notify("No packages installed")
      else
        vim.ui.select(packages, {
          prompt = "Installed packages:",
          format_item = function(item)
            return item
          end
        }, function(choice)
          if choice then
            -- User selected a package, could potentially do something with it
            -- For now, just show a message
            notify("Selected: " .. choice)
          end
        end)
      end
    end
  })

  M.register_subcommand({
    name = "install",
    desc = "Search and install packages from nixpkgs",
    args = {
      { name = "search_string", required = false, desc = "Search term to look for" },
      { name = "nixpkgs_url",   required = false, desc = "Nixpkgs URL to search in (optional)" }
    },
    handler = function(args)
      local function handle_search_results(packages)
        if #packages == 0 then
          return
        end

        -- Create selection items with formatted display
        local selection_items = {}
        for _, pkg in ipairs(packages) do
          table.insert(selection_items, {
            package = pkg,
            display = string.format("%s (v%s) - %s", pkg.name, pkg.version, pkg.description)
          })
        end

        -- Show package selection with install option
        vim.ui.select(selection_items, {
          prompt = "Select package to install:",
          format_item = function(item)
            return item.display
          end
        }, function(choice)
          if choice then
            notify(string.format("Installing %s...", choice.package.name))
            commands.build(choice.package.name)
          end
        end)
      end

      local function perform_search(search_term, nixpkgs_url)
        commands.search(search_term, nixpkgs_url, handle_search_results)
      end

      if #args == 0 then
        -- No arguments provided, prompt for search term
        vim.ui.input({
          prompt = "Enter search term: ",
        }, function(input)
          if input and input ~= "" then
            perform_search(input)
          end
        end)
      else
        -- Search term provided as argument
        perform_search(args[1], args[2])
      end
    end,
    complete = function(args)
      -- Provide some common search term suggestions
      if #args == 0 then
        return {
          "lua-language-server", "pyright", "typescript-language-server", "rust-analyzer", "clangd", "gopls", "jdtls",
          "hls", "nixd", "marksman", "yamlls", "jsonls"
        }
      end
      return {}
    end
  })

  -- Create the main Nix user command
  vim.api.nvim_create_user_command("Nix", nix_command_handler, {
    nargs = "*",
    desc = "Nix package manager integration",
    complete = complete_nix_command
  })
end

return M

-- vim: ts=2 sts=2 sw=2 et
