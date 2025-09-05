local M = {}

M.config = {
  title = "Test Adapter - Debug List Window",
  concurrency = math.max(1, math.floor((vim.uv or vim.loop).available_parallelism() / 2)), -- ensure concurrency is never 0
  debounce = 40,
}

-- Mock data for testing
local available_items = {
  "test-item-1",
  "test-item-2",
  "test-item-3",
  "test-item-4",
  "test-item-5",
}

local checked_items = {}

-- Providers (can be sync; list_window wrapper supports both)
function M.get_all_items()
  return available_items
end

function M.get_checked_items()
  return vim.tbl_keys(checked_items)
end

function M.on_check(name, done)
  -- Simulate async operation
  vim.defer_fn(function()
    checked_items[name] = true
    print("Checked: " .. name)
    vim.schedule(done)
  end, 2000)
end

function M.on_uncheck(name, done)
  -- Simulate async operation
  vim.defer_fn(function()
    checked_items[name] = nil
    print("Unchecked: " .. name)
    vim.schedule(done)
  end, 2000)
end

-- Optional on_open: simulate initialization
function M.on_open(_, done)
  print("Test adapter initialized")
  done()
end

return M
