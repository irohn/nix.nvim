# Adapters

This directory contains adapter modules that plug into the generic `list_window` UI.

Current adapters:
- `lsp.lua` : Manage enabling / disabling discovered LSP servers (uses nix-lsp-manager registry).

To add a new adapter (e.g. plugin manager):
1. Create a module returning a table with fields:
   - config (optional)
   - get_all_items(cb or return list)
   - get_checked_items(cb or return list)
   - on_check(item, done)
   - on_uncheck(item, done)
   - (optional) check_function(item)
   - (optional) on_open(self, done)
2. Call it through a helper in `nix.view` similar to `open_lsp_manager`.
