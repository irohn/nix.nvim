return {
  cmd = require("nix").cmd("basedpyright", { "basedpyright-langserver", "--stdio" })
}
