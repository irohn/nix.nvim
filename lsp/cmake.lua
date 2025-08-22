---@brief
---
--- https://github.com/regen100/cmake-language-server
---
--- CMake LSP Implementation

---@type vim.lsp.Config
return {
  cmd = require("nix").build_nix_shell_cmd("cmake-language-server"),
  filetypes = { 'cmake' },
  root_markers = { 'CMakePresets.json', 'CTestConfig.cmake', '.git', 'build', 'cmake' },
  init_options = {
    buildDirectory = 'build',
  },
}
