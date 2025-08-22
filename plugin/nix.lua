-- set a global for the nix command
_G.nixCmd = require("nix").build_nix_shell_cmd
