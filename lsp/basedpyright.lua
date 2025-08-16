return {
  cmd = require("nix").build_nix_shell_cmd("basedpyright", { "basedpyright-langserver", "--stdio" })
}
