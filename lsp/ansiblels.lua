return {
  cmd = require("nix").build_nix_shell_cmd("ansible-language-server", { "ansible-language-server", "--stdio" })
}
