-- Ensure commands are loaded when plugin is sourced
if vim.g.loaded_nix_nvim then
  return
end
vim.g.loaded_nix_nvim = 1

-- Only auto-setup if user hasn't called setup() explicitly
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if not vim.g.nix_nvim_setup_called then
      require("nix").setup()
    end
  end,
})

-- vim: ts=2 sts=2 sw=2 et
