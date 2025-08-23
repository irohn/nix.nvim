---@brief
---
--- https://github.com/veryl-lang/veryl
---
--- Language server for Veryl
---
--- `veryl-ls` can be installed via `cargo`:
---  ```sh
---  cargo install veryl-ls
---  ```

---@type vim.lsp.Config
return {
  cmd = NixShellCmd('veryl', { 'veryl-ls' }),
  filetypes = { 'veryl' },
  root_markers = { '.git' },
}
