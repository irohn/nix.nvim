return {
  cmd = require("nix").build_nix_shell_cmd("llvmPackages_21.clang-tools", { "clangd" })
}
