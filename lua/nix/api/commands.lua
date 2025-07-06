local notify = require("nix.notify")
local defaults = require("nix.config")._DEFAULT_CONFIG

local M = {}

--- Build a nix package and create an outlink in the data directory
--- @param package string The name of the package to build from nixpkgs
--- @param data_dir? string The directory to store the built package (defaults to config.data_dir)
--- @param flakes? boolean Whether to use flakes experimental feature (defaults to config.experimental_feature.flakes)
--- @param nixpkgs_url? string The nixpkgs URL to build from (defaults to config.nixpkgs.url)
function M.build(package, data_dir, flakes, nixpkgs_url)
  data_dir = data_dir or defaults.data_dir
  flakes = flakes or defaults.experimental_feature.flakes
  nixpkgs_url = nixpkgs_url or defaults.nixpkgs.url
  local outlink = data_dir .. "/" .. package
  local cmd

  if flakes then
    cmd = {
      "nix",
      "--experimental-features",
      "'nix-command flakes'",
      "build",
      nixpkgs_url .. "#" .. package,
      "--out-link",
      outlink
    }
  else
    if nixpkgs_url == "nixpkgs" then nixpkgs_url = "<nixpkgs>" end
    cmd = {
      "nix-build",
      nixpkgs_url,
      "-A",
      package,
      "--out-link",
      outlink
    }
  end

  vim.schedule(function()
    notify(string.format("Building %s ...",
      package))
  end)

  vim.system(cmd, { text = true }, function(obj)
    if obj.code == 0 then
      vim.schedule(function()
        notify(string.format("Successfully built %s at %s",
          package,
          outlink))
      end)
    else
      vim.schedule(function()
        notify(string.format("Failed to build package %s:\n%s",
            package,
            obj.stderr or ""),
          vim.log.levels.ERROR)
      end)
    end
  end)
end

--- Delete a nix package outlink from the data directory
--- @param package string The name of the package to delete
--- @param data_dir? string The directory to delete from (defaults to config.data_dir)
M.delete = function(package, data_dir)
  data_dir = data_dir or defaults.data_dir
  local outlink = data_dir .. "/" .. package

  -- check if outlink exists
  local outlink_exists = vim.fn.isdirectory(outlink) == 1 or vim.fn.filereadable(outlink) == 1
  if not outlink_exists then
    vim.schedule(function()
      notify(string.format("%s not found at %s",
          package,
          outlink),
        vim.log.levels.WARN)
    end)
    return
  end

  -- remove the symlink
  local success = vim.fn.delete(outlink)
  if success == 0 then
    vim.schedule(function()
      notify(string.format("Removed %s from %s",
        package,
        outlink))
    end)
  else
    vim.schedule(function()
      notify(string.format("Failed to delete %s from %s",
          package,
          outlink),
        vim.log.levels.ERROR)
    end)
  end
end

--- Run nix-store garbage collection to clean up unused packages
---
--- Please NOTE that this will clean ALL packages
--- inclding those you did not install with nix.nvim!
--- More information at:
--- https://nix.dev/manual/nix/2.28/command-ref/nix-store.html
M.gc = function()
  -- Prompt user for confirmation
  vim.schedule(function()
    local choice = vim.fn.confirm(
      "Are you sure you want to run garbage collection?\n\nThis will permanently delete unused Nix store paths and cannot be undone.",
      "&Yes\n&No",
      2
    )

    if choice ~= 1 then
      notify("Garbage collection cancelled")
      return
    end

    local cmd = { "nix-store", "--gc" }

    notify("Starting garbage collection...")

    vim.system(cmd, { text = true }, function(obj)
      if obj.code == 0 then
        vim.schedule(function()
          local output = obj.stdout or ""
          local freed_info = output:match("freed (%d+%.?%d*%s*%w+)") or "completed successfully"
          notify(string.format("Garbage collection %s", freed_info))
        end)
      else
        vim.schedule(function()
          notify(string.format("Garbage collection failed:\n%s", obj.stderr or ""), vim.log.levels.ERROR)
        end)
      end
    end)
  end)
end

--- Search for packages in nixpkgs and return structured data
--- @param search_string string The search term to look for
--- @param nixpkgs_url? string The nixpkgs URL to search in (defaults to config.nixpkgs.url)
--- @param callback? function Optional callback function to receive search results
M.search = function(search_string, nixpkgs_url, callback)
  if not search_string or search_string == "" then
    vim.schedule(function()
      notify("Search string cannot be empty", vim.log.levels.WARN)
    end)
    return
  end

  nixpkgs_url = nixpkgs_url or defaults.nixpkgs.url

  -- Build the search command with --json flag
  local cmd = {
    "nix",
    "--extra-experimental-features",
    "nix-command flakes",
    "search",
    nixpkgs_url,
    search_string,
    "--json"
  }

  vim.schedule(function()
    notify(string.format("Searching for '%s' in %s...", search_string, nixpkgs_url))
  end)

  vim.system(cmd, { text = true }, function(obj)
    if obj.code == 0 then
      vim.schedule(function()
        local output = obj.stdout or ""
        if output:match("^%s*$") then
          notify(string.format("No packages found matching '%s'", search_string), vim.log.levels.WARN)
          if callback then callback({}) end
          return
        end

        -- Parse JSON output
        local success, results = pcall(vim.json.decode, output)
        if not success then
          notify("Failed to parse search results", vim.log.levels.ERROR)
          if callback then callback({}) end
          return
        end

        -- Convert results to a more usable format
        local packages = {}
        for package_path, info in pairs(results) do
          -- Extract package name from the path (e.g., "legacyPackages.x86_64-linux.pyright" -> "pyright")
          local package_name = package_path:match("%.([^%.]+)$") or package_path
          table.insert(packages, {
            name = package_name,
            full_path = package_path,
            description = info.description or "No description available",
            pname = info.pname or package_name,
            version = info.version or "unknown"
          })
        end

        -- Sort packages by name for consistent ordering
        table.sort(packages, function(a, b) return a.name < b.name end)

        if callback then
          callback(packages)
        else
          -- Default behavior: display results in a buffer (for backwards compatibility)
          local lines = {}
          table.insert(lines, string.format("Search results for '%s' (%d packages found):", search_string, #packages))
          table.insert(lines, string.rep("=", 60))
          table.insert(lines, "")

          for _, pkg in ipairs(packages) do
            table.insert(lines, string.format("📦 %s (v%s)", pkg.name, pkg.version))
            table.insert(lines, string.format("   %s", pkg.description))
            table.insert(lines, "")
          end

          -- Create a new buffer to display results
          local buf = vim.api.nvim_create_buf(false, true)
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
          vim.bo[buf].filetype = "nixsearch"
          vim.bo[buf].buftype = "nofile"
          vim.bo[buf].modifiable = false

          -- Open in a new window
          vim.cmd("split")
          vim.api.nvim_win_set_buf(0, buf)
          vim.api.nvim_buf_set_name(buf, string.format("Nix Search: %s", search_string))

          notify(string.format("Found %d packages matching '%s'", #packages, search_string))
        end
      end)
    else
      vim.schedule(function()
        local error_msg = obj.stderr or "Unknown error"
        if error_msg:match("error: experimental Nix feature") then
          notify(
            "Nix search requires experimental features. Try enabling 'nix-command flakes' in your nix configuration.",
            vim.log.levels.ERROR
          )
        else
          notify(string.format("Search failed:\n%s", error_msg), vim.log.levels.ERROR)
        end
        if callback then callback({}) end
      end)
    end
  end)
end

return M

-- vim: ts=2 sts=2 sw=2 et
