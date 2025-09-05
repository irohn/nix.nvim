local options = require("nix.config").options
local Plugin = require("nix-plugin-manager.lib.plugin")

local M = {}

M.plugins_scanned = false

function M.scan_plugins(recache, on_complete)
  recache = recache or false
  local path = options.data_dir .. "/available_plugins.json"

  -- Check if cache file exists, or if recache is true
  if vim.fn.filereadable(path) ~= 1 or recache then
    local subset_pattern = "vimPlugins."
    local search_cmd = require("nix.lib.search"):new(subset_pattern).command
    local result = ""
    vim.system(search_cmd, {
      text = true,
      stdout = function(err, data)
        if not err and data then
          result = result .. data
        end
      end,
    }, function(proc)
      local ok = proc.code == 0 and result ~= ""
      if ok then
        local cache_file = io.open(path, "w")
        if cache_file then
          cache_file:write(result)
          cache_file:close()
          M.plugins_scanned = true
          vim.schedule(function()
            vim.notify("Nix Plugin Manager: Plugin cache updated", vim.log.levels.INFO)
          end)
        else
          vim.schedule(function()
            vim.notify("Nix Plugin Manager: Failed to open cache file for writing", vim.log.levels.ERROR)
          end)
          ok = false
        end
      end
      if on_complete then
        on_complete(ok)
      end
    end)
  else
    M.plugins_scanned = true
    if on_complete then
      on_complete(true)
    end
  end
end

function M.setup()
  -- handle plugins in config
  local config_plugins = options.plugin_manager.plugins or nil
  if config_plugins and type(config_plugins) == "table" then
    local installed_plugins = {}

    local function install_plugin_with_deps(plugin_spec)
      if installed_plugins[plugin_spec] then
        return -- Already processed
      end

      local p = Plugin:new(plugin_spec)

      -- Check if plugin has dependencies
      if type(plugin_spec) == "table" and plugin_spec.dependencies then
        for _, dep in ipairs(plugin_spec.dependencies) do
          local dep_found = false
          -- Check if dependency is in config_plugins list
          for _, config_plugin in ipairs(config_plugins) do
            local config_plugin_name = type(config_plugin) == "table" and config_plugin[1] or config_plugin
            local dep_name = type(dep) == "table" and dep[1] or dep
            if config_plugin_name == dep_name then
              install_plugin_with_deps(config_plugin)
              dep_found = true
              break
            end
          end

          -- If dependency not found in config, create new plugin object and install
          if not dep_found then
            install_plugin_with_deps(dep)
          end
        end
      end

      -- Mark as processed before installing
      local plugin_name = type(plugin_spec) == "table" and plugin_spec[1] or plugin_spec
      installed_plugins[plugin_name] = true

      p:install({
        on_exit = function(obj)
          if obj.code == 0 then
            vim.schedule(function()
              if type(plugin_name) == "table" then
                plugin_name = plugin_name.name
              end
              p:load()
              vim.notify("Nix Plugin Manager: Installed " .. plugin_name, vim.log.levels.INFO)
            end)
          else
            vim.schedule(function()
              vim.notify("Nix Plugin Manager: Failed to install " .. plugin_name, vim.log.levels.ERROR)
            end)
          end
        end
      })
    end

    for _, plugin in ipairs(config_plugins) do
      install_plugin_with_deps(plugin)
    end
  end
end

return M
