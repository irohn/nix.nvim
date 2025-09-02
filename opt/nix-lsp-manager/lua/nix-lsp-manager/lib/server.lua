---@class NixLSPServer
---@field name string
local Server = {}
Server.__index = Server

---Create a new server object
---@param opts table|string
function Server:new(opts)
  self = setmetatable({}, self)
  if type(opts) == "string" then
    opts = { name = opts }
  else
    opts = opts or {}
  end
  assert(opts.name, "Server name is required")
  self.name = opts.name
  return self
end

function Server:__toString()
  return string.format("NixLSPServer(name=%s)", self.name)
end

Server.__tostring = Server.__toString

---Enable this server (idempotent)
function Server:enable()
  if vim.lsp.enable then
    vim.lsp.enable(self.name, true)
  else
    vim.notify("vim.lsp.enable not available (Neovim version?)", vim.log.levels.WARN)
  end
end

---Disable this server (idempotent)
function Server:disable()
  if vim.lsp.enable then
    vim.lsp.enable(self.name, false)
  else
    vim.notify("vim.lsp.enable not available (Neovim version?)", vim.log.levels.WARN)
  end
end

---Restart server (disable then enable)
function Server:restart()
  self:disable()
  self:enable()
end

return Server
