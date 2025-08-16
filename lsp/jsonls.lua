return {
  cmd = require("nix").cmd("vscode-langservers-extracted", { "vscode-json-language-server", "--stdio" })
}
