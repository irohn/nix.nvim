local NixPackage = require("nix.lib.package")

---@class NixPlugin
---@field name string
---@field pname string
---@field dependencies string[]
---@field init function|nil
---@field config function|nil
---@field package NixPackage
---@field lazy boolean
---@field loaded boolean
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
  self.lazy = opts.lazy or false              -- whether to load lazily
  self.loaded = false                         -- track if plugin is loaded

  return self
end

---Check if this plugin is installed
---@return boolean
function Plugin:is_installed()
  return self.package:is_built()
end

---Remove the package
function Plugin:uninstall()
  self.package:remove()
  self.loaded = false
end

---Load the plugin (packadd self.pname)
function Plugin:load()
  if self.loaded then
    return true -- already loaded
  end
  
  if not self:is_installed() then
    vim.notify(string.format("[nix-plugin-manager] Cannot load %s: not installed", self.name), vim.log.levels.WARN)
    return false
  end
  
  if self.init then self.init() end
  vim.cmd.packadd(self.pname)
  if self.config then self.config() end
  self.loaded = true
  return true
end

---Build the package
---@param opts table? Options to pass to the package build
---@param on_complete fun(success: boolean)? Callback when installation completes
function Plugin:install(opts, on_complete)
  if type(opts) == "function" then
    on_complete = opts
    opts = {}
  end
  opts = opts or {}
  on_complete = on_complete or function() end
  
  -- Set up timeout (5 minutes)
  local timeout_ms = 5 * 60 * 1000
  local uv = vim.uv or vim.loop
  local timeout_timer = uv.new_timer()
  local completed = false
  
  -- Set up build options with callback
  local build_opts = vim.tbl_deep_extend("force", opts, {
    cmd_opts = vim.tbl_deep_extend("force", opts.cmd_opts or {}, {
      text = true,
      timeout = timeout_ms
    }),
    on_exit = function(obj)
      if completed then return end
      completed = true
      
      if timeout_timer then
        timeout_timer:stop()
        timeout_timer:close()
      end
      
      local success = obj.code == 0
      if success then
        vim.schedule(function()
          vim.notify(string.format("Plugin %s installed successfully!", self.name), vim.log.levels.INFO)
          if not self.lazy then
            self:load()
          end
          on_complete(true)
        end)
      else
        vim.schedule(function()
          vim.notify(string.format("Failed to install plugin %s: %s", self.name, obj.stderr or "Unknown error"), vim.log.levels.ERROR)
          on_complete(false)
        end)
      end
    end
  })
  
  -- Set up timeout handler
  timeout_timer:start(timeout_ms, 0, function()
    if completed then return end
    completed = true
    
    vim.schedule(function()
      vim.notify(string.format("Plugin %s installation timed out after 5 minutes", self.name), vim.log.levels.ERROR)
      on_complete(false)
    end)
  end)
  
  -- Start the build
  self.package:build(build_opts)
end

---Check if all dependencies are loaded
---@return boolean, string[] success, missing dependencies
function Plugin:check_dependencies()
  if not self.dependencies or #self.dependencies == 0 then
    return true, {}
  end
  
  local missing = {}
  for _, dep_name in ipairs(self.dependencies) do
    -- Check if dependency is loaded by looking for it in the package path
    local dep_pname = dep_name:match("^vimPlugins%.") and dep_name or ("vimPlugins." .. dep_name)
    
    -- Try to find the plugin in the loaded packages
    local found = false
    local rtp = vim.opt.runtimepath:get()
    for _, path in ipairs(rtp) do
      if path:find(dep_pname:gsub("%.", "%."), 1, true) then
        found = true
        break
      end
    end
    
    if not found then
      table.insert(missing, dep_name)
    end
  end
  
  return #missing == 0, missing
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
