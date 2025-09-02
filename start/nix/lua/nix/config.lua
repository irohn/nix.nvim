local M = {}

M.defaults = {
	data_dir = vim.fn.stdpath("data") .. "/nix",
	nix = {
		command = { "nix", "--experimental-features", "nix-command flakes" },
		nixpkgs = "nixpkgs",
		allow_unfree = false,
		outlink_dir = vim.fn.stdpath("data") .. "/site/pack/nix/opt",
	},
	plugin_manager = {
		enabled = true,
		plugins = {},
		build_dir = vim.fn.stdpath("data") .. "/site/pack/nix/start",
		settings = {
			auto_install = true,
			auto_scan = true,
			force_rescan = false,
			notify = true,
		},
		window = {
			width = 0.6,
			height = 0.6,
			border = "rounded",
			title = "Plugin Manager",
			icons = {
				checked = "◼",
				unchecked = "◻",
			},
			keys = {
				check = { "i" },
				uncheck = { "u" },
				toggle = { "<CR>" },
				sort = { "s" },
				help = { "?" },
				close = { "q", "<Esc>" },
			},
		},
	},
	lsp_manager = {
		enabled = false,
		servers = {},
		window = {
			width = 0.6,
			height = 0.6,
			border = "rounded",
			title = "LSP Manager",
			icons = {
				checked = "◼",
				unchecked = "◻",
			},
			keys = {
				check = { "i" },
				uncheck = { "u" },
				toggle = { "<CR>" },
				sort = { "s" },
				help = { "?" },
				close = { "q", "<Esc>" },
			},
		},
	},
}

M.options = {}

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
