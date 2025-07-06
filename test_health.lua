-- Test file to verify the health check implementation
-- This can be run in Neovim to test the health functionality

print("=== Testing Nix.nvim Health Checks ===")

-- Setup the plugin first
require("nix").setup()

-- Load the health module
local health = require("nix.health")

-- Test that the health module loads correctly
print("✓ Health module loaded successfully")

-- Test individual helper functions if possible
print("\n=== Testing Health Check Functions ===")

-- Run the main health check
print("Running full health check...")
health.check()

print("\n=== Health Check Test Completed ===")
print("You can also run ':checkhealth nix' in Neovim to see the health check output")

