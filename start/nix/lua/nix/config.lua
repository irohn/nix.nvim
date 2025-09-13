local M = {}

M.defaults = {
	data_dir = vim.fn.stdpath("data") .. "/nix",
	nix = {
		command = { "nix", "--experimental-features", "nix-command flakes" },
		nixpkgs = "nixpkgs",
		allow_unfree = false,
		outlink_dir = vim.fn.stdpath("data") .. "/site/pack/nix/opt",
	},
	window = {
		width = 0.6,
		height = 0.6,
		border = "rounded", -- "none", "single", "double", "rounded", "solid", "shadow" or a table of chars
		icons = {
			checked = vim.g.nerd_font and "󰄯" or "[x]",
			unchecked = vim.g.nerd_font and "󰄰" or "[ ]",
			pending_frames = vim.g.nerd_font and { "", "", "", "", "", "" }
				or { "[|]", "[/]", "[-]", "[\\]" }, -- spinner
			pending = vim.g.nerd_font and "" or "...", -- fallback if spinner disabled
		},
		keys = {
			check = { "i" },
			uncheck = { "u" },
			toggle = { "<CR>" },
			sort = { "s" },
			help = { "?" },
			refresh = { "r" },
			close = { "q", "<Esc>" },
		},
	},
	plugin_manager = {
		enabled = true,
		plugins = {},
	},
	lsp_manager = {
		enabled = false,
		servers = {},
	},
}

M.options = {}

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
