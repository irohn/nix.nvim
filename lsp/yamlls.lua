return {
  cmd = require("nix").build_nix_shell_cmd("yaml-language-server", { "yaml-language-server", "--stdio" })
}
