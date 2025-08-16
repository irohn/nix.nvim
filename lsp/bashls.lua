return {
  cmd = require("nix").cmd("bash-language-server", { "bash-language-server", "start" })
}
