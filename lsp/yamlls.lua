return {
  cmd = require("nix").cmd("yaml-language-server", { "yaml-language-server", "--stdio" })
}
