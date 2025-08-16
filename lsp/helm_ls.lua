return {
  cmd = require("nix").build_nix_shell_cmd("helm-ls", { "helm_ls", "serve" })
}
