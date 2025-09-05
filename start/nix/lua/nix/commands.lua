local M = {}

function M.setup()
  vim.api.nvim_create_user_command("NixUpdate", function(opts)
    local target = vim.fn.expand("~/.config/nvim/pack/nix.nvim")
    local branch = opts.args ~= "" and opts.args or "master"
    local cmd = string.format("cd %s && git fetch origin && git checkout %s && git pull origin %s", target, branch,
      branch)
    local result = vim.fn.system(cmd)
    if vim.v.shell_error == 0 then
      vim.notify(("nix.nvim updated to " .. branch), vim.log.levels.INFO)
    else
      vim.notify(("Failed to update nix.nvim: " .. result), vim.log.levels.ERROR)
    end
  end, { nargs = "?" })
end

return M
