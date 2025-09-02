local nix = require("nix.config").options.nix
local base_command = nix.command
local nixpkgs = nix.nixpkgs

---@class NixSearch
---@field query string Search query
local M = {}
M.__index = M

---Create a new NixSearch instance
---@param opts string|table
--- opts = {
---   query = string search query (required)
--- }
---@return NixSearch
function M:new(opts)
  if type(opts) == "string" then
    opts = { query = opts }
  else
    opts = opts or {}
  end
  self = setmetatable({}, M)

  assert(opts.query, "Search query is required")
  self.query = opts.query
  self.command = vim.list_extend(vim.deepcopy(base_command), {
    "search",
    nixpkgs, self.query,
    "--json",
  })

  return self
end

function M.__tostring(self)
  return string.format("NixSearch(query=%s)", self.query)
end

return M
