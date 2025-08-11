local api = require('nix.lsp.api')

local M = {}

-- UI state
local state = {
  buf = nil,
  win = nil,
  servers = {},
  enabled_servers = {}
}

-- Configuration
local config = {
  width = 60,
  height = 20,
  border = "rounded",
  title = " LSP Server Manager ",
  help_text = {
    "Keybindings:",
    "  i - Enable server",
    "  x - Disable server", 
    "  ? - Show this help",
    "  q - Close window",
    "",
    "Navigate with j/k or arrow keys"
  }
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
    vim.api.nvim_buf_set_option(state.buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(state.buf, 'filetype', 'nix-lsp-manager')
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
    title_pos = "center"
  }
  
  -- Create window
  state.win = vim.api.nvim_open_win(state.buf, true, opts)
  
  -- Set window options
  vim.api.nvim_win_set_option(state.win, 'winblend', 10)
  vim.api.nvim_win_set_option(state.win, 'winhighlight', 'Normal:Normal,FloatBorder:FloatBorder')
  
  return state.buf, state.win
end

-- Update the server list display
local function update_display()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return
  end
  
  -- Get current servers
  state.servers = api.get_all_servers()
  state.enabled_servers = api.get_enabled_servers()
  
  local lines = {}
  
  -- Header
  table.insert(lines, "Enabled    Server")
  table.insert(lines, string.rep("─", config.width - 2))
  
  -- Server list
  for _, server in ipairs(state.servers) do
    local enabled = vim.tbl_contains(state.enabled_servers, server)
    local checkbox = enabled and "[x]" or "[ ]"
    local line = string.format("%s        %s", checkbox, server)
    table.insert(lines, line)
  end
  
  -- Set buffer content
  vim.api.nvim_buf_set_option(state.buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(state.buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(state.buf, 'readonly', true)
end

-- Get server name from current line
local function get_server_from_line()
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

-- Show help in a new floating window
local function show_help()
  local help_buf = vim.api.nvim_create_buf(false, true)
  local help_lines = vim.tbl_extend("force", {config.title}, {""}, config.help_text)
  
  vim.api.nvim_buf_set_lines(help_buf, 0, -1, false, help_lines)
  vim.api.nvim_buf_set_option(help_buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(help_buf, 'readonly', true)
  
  local help_width = 40
  local help_height = #help_lines + 2
  local help_row = math.ceil((vim.o.lines - help_height) / 2 - 1)
  local help_col = math.ceil((vim.o.columns - help_width) / 2)
  
  local help_win = vim.api.nvim_open_win(help_buf, true, {
    style = "minimal",
    relative = "editor",
    width = help_width,
    height = help_height,
    row = help_row,
    col = help_col,
    border = "rounded",
    title = " Help ",
    title_pos = "center"
  })
  
  -- Close help window on any key
  vim.keymap.set('n', '<CR>', function()
    vim.api.nvim_win_close(help_win, true)
  end, { buffer = help_buf })
  
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(help_win, true)
  end, { buffer = help_buf })
  
  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(help_win, true)
  end, { buffer = help_buf })
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
  
  local success, err = api.enable_servers({server})
  if success then
    vim.notify(string.format("Enabled server: %s", server), vim.log.levels.INFO)
    update_display()
  else
    vim.notify(string.format("Failed to enable server '%s': %s", server, err or "unknown error"), vim.log.levels.ERROR)
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
  
  local success, err = api.disable_servers({server})
  if success then
    vim.notify(string.format("Disabled server: %s", server), vim.log.levels.INFO)
    update_display()
  else
    vim.notify(string.format("Failed to disable server '%s': %s", server, err or "unknown error"), vim.log.levels.ERROR)
  end
end

-- Set up keybindings
local function setup_keybindings()
  if not state.buf then
    return
  end
  
  local opts = { buffer = state.buf, silent = true }
  
  -- Enable server
  vim.keymap.set('n', 'i', enable_server, opts)
  
  -- Disable server
  vim.keymap.set('n', 'x', disable_server, opts)
  
  -- Show help
  vim.keymap.set('n', '?', show_help, opts)
  
  -- Close window
  vim.keymap.set('n', 'q', function()
    M.close()
  end, opts)
  
  -- ESC to close
  vim.keymap.set('n', '<Esc>', function()
    M.close()
  end, opts)
end

-- Open the LSP manager UI
function M.open()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    -- Window already open, just focus it
    vim.api.nvim_set_current_win(state.win)
    return
  end
  
  create_window()
  setup_keybindings()
  update_display()
  
  -- Set cursor to first server line
  if #state.servers > 0 then
    vim.api.nvim_win_set_cursor(state.win, {3, 0})
  end
end

-- Close the LSP manager UI
function M.close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win = nil
end

-- Toggle the LSP manager UI
function M.toggle()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    M.close()
  else
    M.open()
  end
end

-- Check if UI is open
function M.is_open()
  return state.win and vim.api.nvim_win_is_valid(state.win)
end

return M