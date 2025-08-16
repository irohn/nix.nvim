return {
  cmd = require("nix").cmd("vscode-langservers-extracted", { "vscode-css-language-server", "--stdio" })
}
