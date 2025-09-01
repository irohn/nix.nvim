-- Adapter for the improved list_window to manage LSP servers
-- Requires optional pack 'nix-lsp-manager' providing registry & server objects.
local M = {}

local function get_registry()
  local ok = pcall(vim.cmd, "packadd nix-lsp-manager")
  if not ok then
    vim.notify("Failed to load nix-lsp-manager (optional pack). Make sure it exists under opt/.", vim.log.levels.ERROR)
  end
  local reg = require("nix-lsp-manager.lib.registry")
  return reg
end

M.config = {
  title = "Nix LSP Servers",
  icons = {
    checked = "✓",
    unchecked = " ",
    pending_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
  },
  keys = {
    toggle = { "<CR>", "t" },
    check = { "e", "+" },
    uncheck = { "d", "-" },
    refresh = { "r" },
    help = { "?" },
    close = { "q", "<Esc>" },
  },
  sort = { checked_first = true },
  concurrency = 4,
  debounce = 40,
}

-- Providers (can be sync; list_window wrapper supports both)
function M.get_all_items()
  local reg = get_registry()
  return reg.list_installed()
end

function M.get_checked_items()
  local reg = get_registry()
  return reg.list_enabled()
end

function M.on_check(name, done)
  local reg = get_registry()
  -- Could perform async operations; here this is immediate
  reg.enable(name)
  vim.schedule(done)
end

function M.on_uncheck(name, done)
  local reg = get_registry()
  reg.disable(name)
  vim.schedule(done)
end

-- Optional on_open: ensure bootstrap executed (enables already cached servers)
function M.on_open(self, done)
  local reg = get_registry()
  reg.bootstrap()
  -- In case new servers added, refresh discovery
  reg.refresh()
  done()
end

return M
