return {
  cmd = require("nix").build_nix_shell_cmd("bash-language-server", { "bash-language-server", "start" })
}
