local M = {}

function M.read_file(path)
	local file = io.open(path, "r")
	if not file then
		return nil, "Could not open file: " .. path
	end
	local content = file:read("*a")
	file:close()
	return content
end

function M.write_file(path, content)
	local file, err = io.open(path, "w")
	if not file then
		return false, "Could not open file for writing: " .. err
	end
	file:write(content)
	file:close()
	return true
end

function M.ensure_directories(dirs)
	for _, dir in ipairs(dirs) do
		if vim.fn.isdirectory(dir) == 0 then
			vim.fn.mkdir(dir, "p")
		end
	end
end

return M
