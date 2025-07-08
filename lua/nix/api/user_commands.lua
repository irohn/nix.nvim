local commands = require("nix.api.commands")
local utils = require("nix.api.utils")
local notify = require("nix.notify")

local M = {}

-- Subcommand registry
local subcommands = {}

-- Alias registry: alias_name -> target_subcommand_name
local aliases = {}

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

--- Register an alias for a subcommand
---@param alias_name string The alias name
---@param target_subcommand string The target subcommand name
function M.register_alias(alias_name, target_subcommand)
	if not subcommands[target_subcommand] then
		error(
			string.format(
				"Cannot create alias '%s': target subcommand '%s' does not exist",
				alias_name,
				target_subcommand
			)
		)
	end
	aliases[alias_name] = target_subcommand
end

--- Resolve an alias or subcommand name to the actual subcommand
---@param name string The alias or subcommand name
---@return string? The resolved subcommand name, or nil if not found
local function resolve_subcommand(name)
	-- First check if it's a direct subcommand
	if subcommands[name] then
		return name
	end

	-- Then check if it's an alias
	if aliases[name] then
		return aliases[name]
	end

	return nil
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

	-- If we're at the first argument (subcommand), complete subcommand names (excluding aliases)
	if #args == 0 or (#args == 1 and not cmd_line:match("%s$")) then
		local candidates = {}
		-- Add only subcommand names, not aliases
		for name, _ in pairs(subcommands) do
			table.insert(candidates, name)
		end
		table.sort(candidates)
		return candidates
	end

	-- If we have a subcommand or alias, resolve it and delegate to its completion function
	local subcommand_name = resolve_subcommand(args[1])
	local subcommand = subcommand_name and subcommands[subcommand_name]

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

		-- Find aliases for this subcommand
		local command_aliases = {}
		for alias, target in pairs(aliases) do
			if target == spec.name then
				table.insert(command_aliases, alias)
			end
		end

		if #command_aliases > 0 then
			table.sort(command_aliases)
			help_text = help_text .. string.format("\nAliases: %s", table.concat(command_aliases, ", "))
		end

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
			-- Find aliases for this subcommand
			local command_aliases = {}
			for alias, target in pairs(aliases) do
				if target == name then
					table.insert(command_aliases, alias)
				end
			end

			local display_name = name
			if #command_aliases > 0 then
				table.sort(command_aliases)
				display_name = name .. " (" .. table.concat(command_aliases, ", ") .. ")"
			end

			table.insert(sorted_commands, { name = display_name, desc = spec.desc })
		end
		table.sort(sorted_commands, function(a, b)
			return a.name < b.name
		end)

		for _, cmd in ipairs(sorted_commands) do
			help_text = help_text .. string.format("\n  %-24s %s", cmd.name, cmd.desc)
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
	args = vim.tbl_filter(function(arg)
		return arg ~= ""
	end, args)

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

	-- Resolve the subcommand (could be an alias)
	local resolved_name = resolve_subcommand(subcommand_name)
	local subcommand = resolved_name and subcommands[resolved_name]

	if not subcommand then
		notify(
			string.format("Unknown subcommand: %s\nUse 'Nix help' to see available subcommands.", subcommand_name),
			vim.log.levels.ERROR
		)
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
			notify(
				string.format(
					"Missing required arguments for '%s': %s\nUse 'Nix help %s' for usage information.",
					subcommand_name,
					table.concat(missing_args, ", "),
					subcommand_name
				),
				vim.log.levels.ERROR
			)
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
		name = "install",
		desc = "Build a nix package",
		args = {
			{ name = "package", required = false, desc = "Package name to build" },
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
	})

	M.register_subcommand({
		name = "remove",
		desc = "Removes a built package symlink",
		args = {
			{ name = "package", required = false, desc = "Package name to delete" },
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
					end,
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
		end,
	})

	M.register_subcommand({
		name = "garbage-collect",
		desc = "Run garbage collection to clean up unused packages",
		handler = function(args)
			commands.gc()
		end,
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
					end,
				}, function(choice)
					if choice then
						-- User selected a package, could potentially do something with it
						-- For now, just show a message
						notify("Selected: " .. choice)
					end
				end)
			end
		end,
	})

	-- Register aliases
	M.register_alias("i", "install")
	M.register_alias("rm", "remove")
	M.register_alias("delete", "remove")
	M.register_alias("gc", "garbage-collect")
	M.register_alias("ls", "list")

	-- Create the main Nix user command
	vim.api.nvim_create_user_command("Nix", nix_command_handler, {
		nargs = "*",
		desc = "Nix package manager integration",
		complete = complete_nix_command,
	})
end

return M

-- vim: ts=2 sts=2 sw=2 et
