return {
  cmd = require("nix").build_nix_shell_cmd("vscode-langservers-extracted", { "vscode-html-language-server", "--stdio" })
}
