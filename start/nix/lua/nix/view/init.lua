local ListWindow = require("nix.view.list_window")

local View = {}

---Open the LSP manager UI
function View.open_lsp_manager()
  local adapter = require("nix.view.adapters.lsp_servers")
  local inst = ListWindow:new(adapter)
  inst:open()
  return inst
end

return View
