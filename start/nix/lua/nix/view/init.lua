local ListWindow = require("nix.view.list_window")

local View = {}

---Open the test UI
function View.open_test_ui()
	local adapter = require("nix.view.adapters.test")
	local inst = ListWindow:new(adapter)
	inst:open()
	return inst
end

---Open the LSP manager UI
function View.open_lsp_manager()
	local adapter = require("nix.view.adapters.lsp")
	local inst = ListWindow:new(adapter)
	inst:open()
	return inst
end

---Open the Plugin manager
function View.open_plugin_manager()
	local adapter = require("nix.view.adapters.plugins")
	local inst = ListWindow:new(adapter)
	inst:open()
	return inst
end

return View
