return {
  cmd = require("nix").cmd("vscode-langservers-extracted", { "vscode-html-language-server", "--stdio" })
}
