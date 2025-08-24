local plugin_manager = require("nix.plugin-manager")

local M = {}

local config = require("nix.config").config.plugin_manager.window

-- UI state
local state = {
  buf = nil,
  win = nil,
  available_plugins = {},
  installed_plugins = {},
  help_buf = nil,
  help_win = nil,
  loading = false,
  footer_messages = {},
}

-- Add a message to the footer
local function add_footer_message(message, level)
  level = level or "info"
  table.insert(state.footer_messages, { message = message, level = level, time = os.time() })
  
  -- Keep only last 10 messages
  if #state.footer_messages > 10 then
    table.remove(state.footer_messages, 1)
  end
  
  -- Update display if window is open
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    update_display()
  end
end

-- Clear footer messages
local function clear_footer_messages()
  state.footer_messages = {}
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    update_display()
  end
end
local function create_window()
  local width = config.width
  local height = config.height

  -- Calculate position to center the window
  local row = math.ceil((vim.o.lines - height) / 2 - 1)
  local col = math.ceil((vim.o.columns - width) / 2)

  -- Create buffer if it doesn't exist
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    state.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = state.buf })
    vim.api.nvim_set_option_value("filetype", "plugin-manager", { buf = state.buf })
  end

  -- Window options
  local opts = {
    style = "minimal",
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = config.border,
    title = config.title,
    title_pos = "center",
  }

  -- Create window
  state.win = vim.api.nvim_open_win(state.buf, true, opts)

  -- Set window options
  vim.api.nvim_set_option_value("winhighlight", "Normal:Normal,FloatBorder:FloatBorder", { win = state.win })

  return state.buf, state.win
end

-- Update the plugin list display
local function update_display(opts)
  opts = opts or { sort = true }
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return
  end

  -- Get current plugins and installed status
  state.installed_plugins = plugin_manager.get_installed_plugins()

  -- Build a set for installed plugins
  local installed_set = {}
  for _, p in ipairs(state.installed_plugins) do
    -- Remove vimPlugins prefix if it exists (shouldn't happen, but just in case)
    local plugin_name = p:match("vimPlugins%.(.+)") or p
    installed_set[plugin_name] = true
  end

  -- Combine all plugins (available + installed)
  local all_plugins = {}
  local plugin_set = {}
  
  -- Add installed plugins first
  for _, plugin in ipairs(state.installed_plugins) do
    -- Remove vimPlugins prefix if it exists (shouldn't happen, but just in case)
    local plugin_name = plugin:match("vimPlugins%.(.+)") or plugin
    if not plugin_set[plugin_name] then
      table.insert(all_plugins, plugin_name)
      plugin_set[plugin_name] = true
    end
  end
  
  -- Add available plugins from search if available
  if state.available_plugins and type(state.available_plugins) == "table" then
    for pkg_name, _ in pairs(state.available_plugins) do
      local plugin_name = pkg_name:match("vimPlugins%.(.+)") or pkg_name
      if not plugin_set[plugin_name] then
        table.insert(all_plugins, plugin_name)
        plugin_set[plugin_name] = true
      end
    end
  end

  -- Sort: installed first, then alphabetically
  if opts.sort then
    table.sort(all_plugins, function(a, b)
      local ia, ib = installed_set[a] or false, installed_set[b] or false
      if ia ~= ib then
        return ia  -- installed ones first
      end
      return a < b -- alphabetical order
    end)
  end

  local lines = {}
  local padding = 2
  local min_header_length = 2
  local headers = config.headers
  local display_headers = true

  -- Headers
  if not config.headers or #config.headers < 2 then
    headers = { "", "" }
    display_headers = false
  end
  local header_widths = {}
  for i, header in ipairs(headers) do
    local col_len = math.max(#header, min_header_length)
    header_widths[i] = col_len + padding
  end
  local header_line = ""
  for i, header in ipairs(headers) do
    header_line = header_line .. string.format("%-" .. header_widths[i] .. "s", header)
  end
  if display_headers then
    table.insert(lines, header_line)
    table.insert(lines, string.rep("─", config.width))
  end

  -- Show loading message if scanning
  if state.loading then
    table.insert(lines, "Scanning plugins...")
    table.insert(lines, "")
  end

  -- Plugin list
  for _, plugin in ipairs(all_plugins) do
    local icon = installed_set[plugin] and config.icons.installed or config.icons.disabled

    -- Center icon in first column
    local icon_padding = math.floor((header_widths[1] + padding - #icon) / 2)
    local icon_col = string.rep(" ", icon_padding) .. icon .. string.rep(" ", header_widths[1] - #icon - icon_padding)

    -- Left-align plugin in second column
    local plugin_col = string.format("%-" .. header_widths[2] .. "s", plugin)

    local line = icon_col .. string.format("%-" .. padding .. "s", ' ') .. plugin_col
    table.insert(lines, line)
  end

  -- Calculate available height for plugin list (total height - header - footer)
  local footer_height = 2
  local main_height = config.height - footer_height
  if display_headers then
    main_height = main_height - 2  -- Subtract header lines
  end
  
  -- Pad or truncate plugin list to fit main area
  local current_content_lines = display_headers and 2 or 0
  if state.loading then
    current_content_lines = current_content_lines + 2
  end
  current_content_lines = current_content_lines + #all_plugins
  
  -- Add empty lines to fill main area if needed
  while #lines < main_height then
    table.insert(lines, "")
  end
  
  -- Truncate if too many lines
  while #lines > main_height do
    table.remove(lines)
  end

  -- Add footer separator
  table.insert(lines, string.rep("─", config.width))
  
  -- Add footer messages (last 2 lines)
  local footer_lines = {}
  if #state.footer_messages > 0 then
    -- Show the most recent messages
    local start_idx = math.max(1, #state.footer_messages - 1)
    for i = start_idx, #state.footer_messages do
      local msg = state.footer_messages[i]
      if msg then
        table.insert(footer_lines, msg.message)
      end
    end
  end
  
  -- Ensure exactly 2 footer lines
  while #footer_lines < footer_height then
    table.insert(footer_lines, "")
  end
  while #footer_lines > footer_height do
    table.remove(footer_lines, 1)
  end
  
  -- Add footer lines to main lines
  for _, line in ipairs(footer_lines) do
    table.insert(lines, line)
  end

  -- Set buffer content
  vim.api.nvim_set_option_value("modifiable", true, { buf = state.buf })
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = state.buf })

  return all_plugins
end

-- Get plugin name from current line
local function get_plugin_from_line()
  if not state.win or not vim.api.nvim_win_is_valid(state.win) then
    return nil
  end

  local line_num = vim.api.nvim_win_get_cursor(state.win)[1]

  if config.headers then
    -- Skip header lines (first 2 lines)
    if line_num <= 2 then
      return nil
    end
  end

  local index_offset = config.headers and 2 or 0
  if state.loading then
    index_offset = index_offset + 2  -- Skip loading message
  end

  local plugin_index = line_num - index_offset
  -- Use the same sorting as the display to ensure correct plugin selection
  local all_plugins = update_display({ sort = true })
  
  if plugin_index > 0 and plugin_index <= #all_plugins then
    return all_plugins[plugin_index]
  end

  return nil
end

-- Install plugin at current line
local function install_plugin()
  local plugin = get_plugin_from_line()
  if not plugin then
    add_footer_message("No plugin found on current line", "warn")
    return
  end

  local installed_plugins = plugin_manager.get_installed_plugins()
  if vim.tbl_contains(installed_plugins, plugin) then
    add_footer_message(string.format("Plugin '%s' is already installed", plugin), "info")
    return
  end

  -- Start installation
  add_footer_message(string.format("Installing plugin: %s", plugin), "info")
  
  plugin_manager.install_plugin_async("vimPlugins." .. plugin, function(success, plugin_name)
    if success then
      add_footer_message(string.format("Successfully installed plugin: %s", plugin), "info")
      -- Refresh display
      vim.schedule(function()
        update_display()
      end)
    else
      add_footer_message(string.format("Failed to install plugin: %s", plugin), "error")
    end
  end)
end

-- Remove plugin at current line
local function remove_plugin()
  local plugin = get_plugin_from_line()
  if not plugin then
    add_footer_message("No plugin found on current line", "warn")
    return
  end

  local installed_plugins = plugin_manager.get_installed_plugins()
  if not vim.tbl_contains(installed_plugins, plugin) then
    add_footer_message(string.format("Plugin '%s' is not installed", plugin), "info")
    return
  end

  add_footer_message(string.format("Removing plugin: %s", plugin), "info")
  local success = plugin_manager.remove_plugin(plugin)
  if success then
    add_footer_message(string.format("Removed plugin: %s", plugin), "info")
    update_display()
  else
    add_footer_message(string.format("Failed to remove plugin '%s'", plugin), "error")
  end
end

-- Toggle plugin at current line
local function toggle_plugin()
  local plugin = get_plugin_from_line()
  if not plugin then
    add_footer_message("No plugin found on current line", "warn")
    return
  end
  
  local installed_plugins = plugin_manager.get_installed_plugins()
  if vim.tbl_contains(installed_plugins, plugin) then
    remove_plugin()
  else
    install_plugin()
  end
end

-- Rescan vim plugins
local function rescan_plugins()
  state.loading = true
  clear_footer_messages()  -- Clear previous messages when starting rescan
  add_footer_message("Rescanning vim plugins...", "info")
  update_display()
  
  plugin_manager.get_available_plugins(true, true, function(plugins)
    state.loading = false
    state.available_plugins = plugins or {}
    vim.schedule(function()
      if plugins then
        add_footer_message("Plugin scan complete", "info")
      else
        add_footer_message("Plugin scan failed", "error")
      end
      update_display()
    end)
  end)
end

-- Show help in a new floating window
local function show_help()
  -- Close existing help window if open
  if state.help_win and vim.api.nvim_win_is_valid(state.help_win) then
    vim.api.nvim_win_close(state.help_win, true)
  end
  if state.help_buf and vim.api.nvim_buf_is_valid(state.help_buf) then
    vim.api.nvim_buf_delete(state.help_buf, { force = true })
  end

  -- Generate help content dynamically from keybindings
  local help_lines = {
    "Keybindings:",
    "",
  }

  -- Add keybindings with descriptions
  for action, keys in pairs(config.keys) do
    table.insert(help_lines, string.format("  %-20s '%s'",
      action:gsub("_", " "), table.concat(keys, "' or '")))
  end

  state.help_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(state.help_buf, 0, -1, false, help_lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = state.help_buf })

  local help_width = 40
  local help_height = #help_lines + 1
  local help_row = math.ceil((vim.o.lines - help_height) / 2 - 1)
  local help_col = math.ceil((vim.o.columns - help_width) / 2)

  state.help_win = vim.api.nvim_open_win(state.help_buf, true, {
    style = "minimal",
    relative = "editor",
    width = help_width,
    height = help_height,
    row = help_row,
    col = help_col,
    border = "rounded",
    title = " Help ",
    title_pos = "center",
  })

  -- Close help window on any key press
  local close_help = function()
    if state.help_win and vim.api.nvim_win_is_valid(state.help_win) then
      vim.api.nvim_win_close(state.help_win, true)
      state.help_win = nil
    end
    if state.help_buf and vim.api.nvim_buf_is_valid(state.help_buf) then
      vim.api.nvim_buf_delete(state.help_buf, { force = true })
      state.help_buf = nil
    end
  end

  local help_opts = { buffer = state.help_buf, silent = true }
  vim.keymap.set("n", "<ESC>", close_help, help_opts)
  vim.keymap.set("n", "q", close_help, help_opts)
  vim.keymap.set("n", "<Enter>", close_help, help_opts)
  vim.keymap.set("n", "?", close_help, help_opts)
end

-- Set up keybindings
local function setup_keybindings()
  if not state.buf then
    return
  end

  local opts = { buffer = state.buf, silent = true }
  local action_functions = {
    remove_plugin = remove_plugin,
    install_plugin = install_plugin,
    toggle_plugin = toggle_plugin,
    show_help = show_help,
    close_window = M.close,
    rescan_plugins = rescan_plugins,
  }

  -- Set up all configured keybindings
  for action, keys in pairs(config.keys) do
    for _, key in ipairs(keys) do
      vim.keymap.set("n", key, action_functions[action], opts)
    end
  end
end

-- Open the plugin manager window
function M.open()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    -- Window already open, just focus it
    vim.api.nvim_set_current_win(state.win)
    return
  end

  create_window()
  
  -- Load available plugins if not already loaded
  if not state.available_plugins or vim.tbl_isempty(state.available_plugins) then
    plugin_manager.get_available_plugins(false, true, function(plugins)
      state.available_plugins = plugins or {}
      vim.schedule(function()
        update_display()
      end)
    end)
  end
  
  local all_plugins = update_display()
  setup_keybindings()

  -- Set cursor to first plugin line
  if #all_plugins > 0 then
    local starting_line = config.headers and 3 or 1
    if state.loading then
      starting_line = starting_line + 2
    end
    vim.api.nvim_win_set_cursor(state.win, { starting_line, 0 })
  end
end

-- Close the plugin manager window
function M.close()
  -- Close help window if open
  if state.help_win and vim.api.nvim_win_is_valid(state.help_win) then
    vim.api.nvim_win_close(state.help_win, true)
    state.help_win = nil
  end
  if state.help_buf and vim.api.nvim_buf_is_valid(state.help_buf) then
    vim.api.nvim_buf_delete(state.help_buf, { force = true })
    state.help_buf = nil
  end

  -- Close main window
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
    state.win = nil
  end
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    vim.api.nvim_buf_delete(state.buf, { force = true })
    state.buf = nil
  end
end

-- Toggle the plugin manager window
function M.toggle()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    M.close()
  else
    M.open()
  end
end

-- Configure the UI (optional, for customization)
function M.setup(opts)
  if opts then
    config = vim.tbl_deep_extend("force", config, opts)
    -- If new keybindings are provided, ensure they can reference the local functions
    if opts.keys then
      for key, binding in pairs(opts.keys) do
        config.keys[key] = binding
      end
    end
  end
end

-- Export internal functions for advanced customization
M.install_plugin = install_plugin
M.remove_plugin = remove_plugin
M.rescan_plugins = rescan_plugins
M.add_footer_message = add_footer_message
M.clear_footer_messages = clear_footer_messages

return M
