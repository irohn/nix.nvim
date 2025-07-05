local M = {}

--- Build a nix package and create an outlink in the data directory
--- @param package string The name of the package to build from nixpkgs
function M.build(package)
  local nix = require("nix")
  local data_dir = nix.options.data_dir
  local flakes = nix.options.experimental_features.flakes
  local nixpkgs_url = nix.options.nixpkgs_url
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

  vim.system(cmd, { text = true }, function(obj)
    if obj.code == 0 then
      vim.schedule(function()
        vim.notify("nix.nvim: Built " .. package .. " to " .. outlink, vim.log.levels.INFO)
      end)
    else
      vim.schedule(function()
        vim.notify("nix.nvim: Failed to build " .. package .. ":\n" .. (obj.stderr or ""), vim.log.levels.ERROR)
      end)
    end
  end)
end

--- Delete a nix package outlink from the data directory
--- @param package string The name of the package to delete
M.delete = function(package)
  local nix = require("nix")
  local data_dir = nix.options.data_dir
  local outlink = data_dir .. "/" .. package

  -- check if outlink exists
  local outlink_exists = vim.fn.isdirectory(outlink) == 1 or vim.fn.filereadable(outlink) == 1
  if not outlink_exists then
    vim.schedule(function()
      vim.notify("nix.nvim: " .. package .. " not found at " .. outlink, vim.log.levels.WARN)
    end)
    return
  end

  -- remove the symlink
  local success = vim.fn.delete(outlink)
  if success == 0 then
    vim.schedule(function()
      vim.notify("nix.nvim: Deleted " .. package .. " from " .. outlink, vim.log.levels.INFO)
    end)
  else
    vim.schedule(function()
      vim.notify("nix.nvim: Failed to delete " .. package .. " from " .. outlink, vim.log.levels.ERROR)
    end)
  end
end

--- Run nix-store garbage collection to clean up unused packages
M.gc = function()
  -- Prompt user for confirmation
  vim.schedule(function()
    local choice = vim.fn.confirm(
      "Are you sure you want to run garbage collection?\n\nThis will permanently delete unused Nix store paths and cannot be undone.",
      "&Yes\n&No",
      2
    )

    if choice ~= 1 then
      vim.notify("nix.nvim: Garbage collection cancelled", vim.log.levels.INFO)
      return
    end

    local cmd = { "nix-store", "--gc" }

    vim.notify("nix.nvim: Starting garbage collection...", vim.log.levels.INFO)

    vim.system(cmd, { text = true }, function(obj)
      if obj.code == 0 then
        vim.schedule(function()
          local output = obj.stdout or ""
          local freed_info = output:match("freed (%d+%.?%d*%s*%w+)") or "completed successfully"
          vim.notify("nix.nvim: Garbage collection " .. freed_info, vim.log.levels.INFO)
        end)
      else
        vim.schedule(function()
          vim.notify("nix.nvim: Garbage collection failed:\n" .. (obj.stderr or ""), vim.log.levels.ERROR)
        end)
      end
    end)
  end)
end

return M

-- vim: ts=2 sts=2 sw=2 et
