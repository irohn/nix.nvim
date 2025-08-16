return {
  cmd = require("nix").build_nix_shell_cmd("rustup", { "rust-analyzer" })
}
