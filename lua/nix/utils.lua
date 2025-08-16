local M = {}

---Internal: read file contents safely.
---@param path string
---@return string[]|nil lines
---@return string? err
function M.read_lines(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return nil, ("failed to read cache file '%s': %s"):format(path, lines)
  end
  return lines
end

return M
