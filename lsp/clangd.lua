return {
  cmd = require("nix").cmd("llvmPackages_21.clang-tools", { "clangd" })
}
