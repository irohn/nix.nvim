local nix = require("nix.config").options.nix
local base_command = nix.command
local nixpkgs = nix.nixpkgs

---@class NixSearch
---@field query string Search query
local Search = {}
Search.__index = Search

--- Create a new NixSearch instance
--- @param opts string|table Search query string or options table with query field
--- @return NixSearch
function Search:new(opts)
	if type(opts) == "string" then
		opts = { query = opts }
	else
		opts = opts or {}
	end
	self = setmetatable({}, Search)

	assert(opts.query, "Search query is required")
	self.query = opts.query
	self.command = vim.list_extend(vim.deepcopy(base_command), {
		"search",
		nixpkgs,
		self.query,
		"--json",
	})

	return self
end

function Search.__tostring(self)
	return string.format("NixSearch(query=%s)", self.query)
end

return Search
