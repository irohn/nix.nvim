local TITLE = "nix.nvim"

return function(message, level)
  level = level or vim.log.levels.INFO
  vim.notify(message, level, {
    title = TITLE
  })
end
