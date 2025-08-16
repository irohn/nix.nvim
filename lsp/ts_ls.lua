return {
  cmd = require("nix").cmd("typescript-language-server", { "typescript-language-server", "--stdio" })
}
