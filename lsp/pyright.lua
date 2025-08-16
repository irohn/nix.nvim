return {
  cmd = require("nix").cmd("pyright", { "pyright-langserver", "--stdio" })
}
