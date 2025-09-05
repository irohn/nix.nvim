local NixPackage = require("nix.lib.package")

---@class NixPlugin
---@field name string
local Plugin = {}
Plugin.__index = Plugin

---Create a new plugin object
---@param opts table|string Options table or plugin name string
function Plugin:new(opts)
  self = setmetatable({}, self)
  if type(opts) == "string" then
    opts = { name = opts }
  else
    opts = opts or {}
  end
  assert(opts.name, "Plugin name is required")

  self.name = opts.name
  self.pname = opts.pname or (function()
    -- if the plugin name doesn't include "vimPlugins.", prepend it
    if vim.startswith(self.name, "vimPlugins.") then
      return self.name
    else
      return "vimPlugins." .. self.name
    end
  end)()
  self.dependencies = opts.dependencies or {} -- list of plugin names this plugin depends on
  self.init = opts.init or nil                -- user init function to run before plugin is loaded
  self.config = opts.config or nil            -- user config function to run after plugin is loaded
  self.package = opts.package or NixPackage:new({ name = self.pname })
  self.lazy = false                           -- currently not supported

  return self
end

---Remove the package
function Plugin:uninstall()
  self.package:remove()
end

---Load the plugin (packadd self.pname)
function Plugin:load()
  if self.init then self.init() end
  vim.cmd.packadd(self.pname)
  if self.config then self.config() end
end

---Build the package
---@param opts table? Options to pass to the package build
function Plugin:install(opts)
  self.package:build(opts)
end

Plugin.__tostring = function(self)
  return string.format([[
    NixPlugin(
      name=%s,
      pname=%s,
      package=%s,
      dependencies=%s,
      init=%s,
      config=%s,
    )
  ]], self.name, self.pname, tostring(self.package), vim.inspect(self.dependencies), tostring(self.init),
    tostring(self.config))
end

return Plugin
