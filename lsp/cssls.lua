return {
  cmd = require("nix").build_nix_shell_cmd("vscode-langservers-extracted", { "vscode-css-language-server", "--stdio" })
}
