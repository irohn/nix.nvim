return {
  cmd = require("nix").build_nix_shell_cmd("typescript-language-server", { "typescript-language-server", "--stdio" })
}
