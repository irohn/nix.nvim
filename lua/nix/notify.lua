local TITLE = "nix.nvim"

return function(message, level)
	level = level or vim.log.levels.INFO
	vim.notify(message, level, {
		title = TITLE,
	})
end

-- vim: ts=2 sts=2 sw=2 et
