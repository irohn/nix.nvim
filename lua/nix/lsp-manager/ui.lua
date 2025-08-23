local lsp_manager = require("nix.lsp-manager")

local M = {}

local config = require("nix.config").config.lsp_manager.window

-- UI state
local state = {
  buf = nil,
  win = nil,
  servers = {},
  enabled_servers = {},
  help_buf = nil,
  help_win = nil,
}

-- Create the floating window
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
    vim.api.nvim_set_option_value("filetype", "lsp-manager", { buf = state.buf })
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

-- Update the server list display
local function update_display(opts)
  opts = opts or { sort = true }
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return
  end

  -- Get current servers and enabled status
  state.servers = lsp_manager.get_runtime_lsp_server_names()
  state.enabled_servers = lsp_manager.get_enabled_servers()

  -- Build a set for enabled servers
  local enabled_set = {}
  for _, s in ipairs(state.enabled_servers) do
    enabled_set[s] = true
  end

  -- Sort: enabled first, then alphabetically
  if opts.sort then
    table.sort(state.servers, function(a, b)
      local ea, eb = enabled_set[a] or false, enabled_set[b] or false
      if ea ~= eb then
        return ea  -- enabled ones first
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

  -- Server list
  for _, server in ipairs(state.servers) do
    local icon = enabled_set[server] and config.icons.enabled or config.icons.disabled

    -- Center icon in first column
    local icon_padding = math.floor((header_widths[1] + padding - #icon) / 2)
    local icon_col = string.rep(" ", icon_padding) .. icon .. string.rep(" ", header_widths[1] - #icon - icon_padding)

    -- Left-align server in second column
    local server_col = string.format("%-" .. header_widths[2] .. "s", server)

    local line = icon_col .. string.format("%-" .. padding .. "s", ' ') .. server_col
    table.insert(lines, line)
  end

  -- Set buffer content
  vim.api.nvim_set_option_value("modifiable", true, { buf = state.buf })
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = state.buf })
end

-- Get server name from current line
local function get_server_from_line()
  if not state.win or not vim.api.nvim_win_is_valid(state.win) then
    return nil
  end

  local line_num = vim.api.nvim_win_get_cursor(state.win)[1]

  -- Skip header lines (first 2 lines)
  if line_num <= 2 then
    return nil
  end

  local server_index = line_num - 2
  if server_index > 0 and server_index <= #state.servers then
    return state.servers[server_index]
  end

  return nil
end

-- Enable server at current line
local function enable_server()
  local server = get_server_from_line()
  if not server then
    vim.notify("No server found on current line", vim.log.levels.WARN)
    return
  end

  if vim.tbl_contains(state.enabled_servers, server) then
    vim.notify(string.format("Server '%s' is already enabled", server), vim.log.levels.INFO)
    return
  end

  local success, err = lsp_manager.enable_servers({ server })
  if success then
    vim.notify(string.format("Enabled server: %s", server), vim.log.levels.INFO)
    update_display()
  else
    vim.notify(
      string.format("Failed to enable server '%s': %s", server, err or "unknown error"),
      vim.log.levels.ERROR
    )
  end
end

-- Disable server at current line
local function disable_server()
  local server = get_server_from_line()
  if not server then
    vim.notify("No server found on current line", vim.log.levels.WARN)
    return
  end

  if not vim.tbl_contains(state.enabled_servers, server) then
    vim.notify(string.format("Server '%s' is already disabled", server), vim.log.levels.INFO)
    return
  end

  local success, err = lsp_manager.disable_servers({ server })
  if success then
    vim.notify(string.format("Disabled server: %s", server), vim.log.levels.INFO)
    update_display({ sort = false })
  else
    vim.notify(
      string.format("Failed to disable server '%s': %s", server, err or "unknown error"),
      vim.log.levels.ERROR
    )
  end
end

-- Toggle server at current line
local function toggle_server()
  local server = get_server_from_line()
  if not server then
    vim.notify("No server found on current line", vim.log.levels.WARN)
    return
  end
  if vim.tbl_contains(state.enabled_servers, server) then
    disable_server()
  else
    enable_server()
  end
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
    disable_server = disable_server,
    enable_server = enable_server,
    toggle_server = toggle_server,
    show_help = show_help,
    close_window = M.close
  }

  -- Set up all configured keybindings
  for action, keys in pairs(config.keys) do
    for _, key in ipairs(keys) do
      vim.keymap.set("n", key, action_functions[action], opts)
    end
  end
end

-- Open the LSP manager window
function M.open()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    -- Window already open, just focus it
    vim.api.nvim_set_current_win(state.win)
    return
  end

  create_window()
  update_display()
  setup_keybindings()

  -- Set cursor to first server line
  if #state.servers > 0 then
    local starting_line = config.headers and 3 or 1
    vim.api.nvim_win_set_cursor(state.win, { starting_line, 0 })
  end
end

-- Close the LSP manager window
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

-- Toggle the LSP manager window
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
M.enable_server = enable_server
M.disable_server = disable_server
M.toggle_server = toggle_server
M.show_help = show_help

return M
