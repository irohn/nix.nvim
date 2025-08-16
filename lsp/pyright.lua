return {
  cmd = require("nix").build_nix_shell_cmd("pyright", { "pyright-langserver", "--stdio" })
}
