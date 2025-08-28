local pm = require("nix.plugin-manager")
local window_config = require("nix.config").config.plugin_manager.window

local state = {
  buf = nil,
  win = nil,
  help_buf = nil,
  help_win = nil,
  installed_plugins = pm.get_installed_plugins(),
  scanned_plugins = pm.get_scanned_plugins(),
}

local function create_floating_window(opts)
  -- Set default options if not provided
  opts = opts or {
    width = window_config.width,
    height = window_config.height,
    border = window_config.border,
    title = window_config.title,
    ft = "nix-plugin-manager",
  }

  local width = math.floor(vim.o.columns * opts.width)
  local height = math.floor(vim.o.lines * opts.height)

  -- Center the window
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Create a buffer if it doesn't exist or is invalid
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    state.buf = vim.api.nvim_create_buf(false, true) -- Create a scratch buffer

    -- Set buffer options
    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = state.buf })
    vim.api.nvim_set_option_value("filetype", opts.ft, { buf = state.buf })
  end

  local win_config = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = opts.border,
    title = opts.title,
    title_pos = "center",
  }

  -- Create the floating window
  local win = vim.api.nvim_open_win(state.buf, true, win_config) -- win is always an integer (window id)

  return { buf = state.buf, win = win }
end

local function update_display(opts)
  opts = opts or {}

  -- Ensure buffer is valid
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return
  end

  local installed_set = {}
  for _, plugin in ipairs(state.installed_plugins) do
    local name = plugin:match('^vimPlugins%.(.+)') or plugin
    installed_set[name] = true
  end

  -- sort installed first, then alphabetically
  table.sort(state.scanned_plugins, function(a, b)
    local a_installed = installed_set[a] or false
    local b_installed = installed_set[b] or false
    if a_installed == b_installed then
      return a < b
    else
      return a_installed
    end
  end)

  local lines = {}

  for _, plugin in ipairs(state.scanned_plugins) do
    local status = installed_set[plugin] and window_config.icons.enabled or window_config.icons.disabled
    table.insert(lines, string.format("%s %s", status, plugin))
  end

  -- Set buffer content
  vim.api.nvim_set_option_value("modifiable", true, { buf = state.buf })
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = state.buf })
end

local function get_plugin_at_cursor()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1]
  local icons = { window_config.icons.enabled, window_config.icons.disabled }
  local text = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1]
  for _, icon in ipairs(icons) do
    text = text:gsub(vim.pesc(icon), ""):gsub("%s+", "")
  end

  return text
end

local function install_plugin()
  local plugin = get_plugin_at_cursor()
  if not plugin or plugin == "" then
    print("No plugin found at cursor")
    return
  end

  local plugin_package_name = "vimPlugins." .. plugin

  print("Installing plugin:", plugin)
  pm.install_plugin(plugin_package_name, function(success, code)
    if success then
      print("Plugin installed:", plugin)
      state.installed_plugins = pm.get_installed_plugins()
      vim.schedule(update_display)
    else
      print(string.format("Failed to install plugin %s (code %d)", plugin, code))
    end
  end)
end

local function remove_plugin()
  local plugin = get_plugin_at_cursor()
  if not plugin or plugin == "" then
    print("No plugin found at cursor")
    return
  end

  local plugin_package_name = "vimPlugins." .. plugin
  local plugin_path = string.format("%s/%s", require("nix.config").config.plugin_manager.build_dir, plugin_package_name)

  if vim.fn.isdirectory(plugin_path) == 0 then
    print("Plugin is already removed: ", plugin)
    state.installed_plugins = pm.get_installed_plugins()
    update_display()
    return
  end

  -- Remove the plugin directory
  local ok, err = pcall(pm.remove_plugin, plugin_package_name)
  if not ok then
    print("Error removing plugin:", err)
    return
  end

  print("Plugin removed:", plugin)
  state.installed_plugins = pm.get_installed_plugins()
  update_display()
end

local function toggle_plugin()
  local plugin = get_plugin_at_cursor()
  if not plugin or plugin == "" then
    print("No plugin found at cursor")
    return
  end

  if vim.tbl_contains(state.installed_plugins, plugin) then
    remove_plugin()
  else
    install_plugin()
  end
end

local function show_help()
  if state.help_win and vim.api.nvim_win_is_valid(state.help_win) then
    vim.api.nvim_set_current_win(state.help_win)
    return
  end

  -- Create help buffer
  if not state.help_buf or not vim.api.nvim_buf_is_valid(state.help_buf) then
    state.help_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = state.help_buf })
    vim.api.nvim_set_option_value("filetype", "nix-plugin-manager-help", { buf = state.help_buf })
  end

  local help_lines = {
    "Keybindings:",
  }

  for action, keys in pairs(window_config.keys) do
    table.insert(help_lines, string.format("  %s: %s", action:gsub("_", " "), table.concat(keys, ", ")))
  end

  table.insert(help_lines, "")
  table.insert(help_lines, "Press 'q' to close this help window.")

  vim.api.nvim_set_option_value("modifiable", true, { buf = state.help_buf })
  vim.api.nvim_buf_set_lines(state.help_buf, 0, -1, false, help_lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = state.help_buf })

  local width = math.floor(vim.o.columns * 0.3)
  local height = math.floor(vim.o.lines * 0.5)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local help_win_config = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = "Help",
    title_pos = "center",
  }

  state.help_win = vim.api.nvim_open_win(state.help_buf, true, help_win_config)

  -- Set all keys in window_config.keys.<action> tables to close the help window
  local function close_help_win()
    if state.help_win and vim.api.nvim_win_is_valid(state.help_win) then
      vim.api.nvim_win_close(state.help_win, true)
      state.help_win = nil
    end
  end

  -- Ensure 'q' and '<Esc>' are always set
  local keys_to_set = { 'q', '<Esc>' }

  -- Collect all keys from window_config.keys.<action> tables
  if window_config and window_config.keys then
    for _, keys in pairs(window_config.keys) do
      if type(keys) == 'table' then
        for _, key in ipairs(keys) do
          table.insert(keys_to_set, key)
        end
      elseif type(keys) == 'string' then
        table.insert(keys_to_set, keys)
      end
    end
  end

  -- Deduplicate keys
  local unique_keys = {}
  for _, key in ipairs(keys_to_set) do
    unique_keys[key] = true
  end

  -- Set keymaps for all unique keys
  for key, _ in pairs(unique_keys) do
    vim.keymap.set('n', key, close_help_win, { buffer = state.help_buf, noremap = true, silent = true })
  end
end

local function close_window()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
    state.win = nil
  end
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    vim.api.nvim_buf_delete(state.buf, { force = true })
    state.buf = nil
  end
end

local function set_keybindings(opts)
  opts = opts or window_config.keys
  if not state.buf then
    return
  end

  local actions = {
    install_plugin = install_plugin,
    remove_plugin = remove_plugin,
    toggle_plugin = toggle_plugin,
    show_help = show_help,
    close_window = close_window
  }

  for action, keys in pairs(opts) do
    local func = actions[action]
    if func then
      for _, key in ipairs(keys) do
        vim.keymap.set('n', key, func, { buffer = state.buf, noremap = true, silent = true })
      end
    end
  end
end

local M = {}

function M.close()
  close_window()
end

function M.open()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    -- Window already open, just focus it
    vim.api.nvim_set_current_win(state.win)
    return
  end

  create_floating_window()
  update_display()
  set_keybindings()
end

return M
