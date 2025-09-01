local NixShell = require("nix.lib.shell")

function _G.NixLspShellCmd(package, args)
  if not args then
    args = { package }
  end
  local shell = NixShell:new(package)
  return shell:generate_command(args)
end
