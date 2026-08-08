local M = {}

M.config = {
	ignored_ts_nodes = {
		"line_comment",
		"comment",
		"string",
	},
	width = 40,
    mappings = {
        round = "<leader>(",
        square = "<leader>[",
        curly = "<leader>{",
    },
}

function match_delimiter(open, close, ignored_ts_node)
	local bufnr = 0
	local parser = vim.treesitter.get_parser(bufnr)
	local tree = parser:parse()[1]
	local root = tree:root()

	local ignored = {}
	for _, node_type in ipairs(ignored_ts_node) do
		ignored[node_type] = true
	end

	local ignored_ranges = {}
	local function walk(node)
		if ignored[node:type()] then
			local sr, sc, er, ec = node:range()
			table.insert(ignored_ranges, {
				sr = sr,
				sc = sc,
				er = er,
				ec = ec,
			})
			return
		end

		for child in node:iter_children() do
			walk(child)
		end
	end
	walk(root)

	local function is_ignored(row, col)
		for _, range in ipairs(ignored_ranges) do
			if row >= range.sr and row <= range.er then
				if row > range.sr and row < range.er then
					return true
				elseif row == range.sr and row == range.er then
					return col >= range.sc and col < range.ec
				elseif row == range.sr then
					return col >= range.sc
				elseif row == range.er then
					return col < range.ec
				end
			end
		end
		return false
	end

    local lines
    if vim.fn.mode():match("[vV\22]") then
        local start_line = vim.fn.line("'<") - 1
        local end_line = vim.fn.line("'>")

        lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line, false)
    else
        lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    end

	local balance = 0
	local output = {}

	for row, line in ipairs(lines) do
		local line_number = row
		for col = 1, #line do
			local ts_row = row - 1
			local ts_col = col - 1
			if not is_ignored(ts_row, ts_col) then
				local char = line:sub(col, col)
				if char == open then
					balance = balance + 1
				elseif char == close then
					balance = balance - 1
				end
			end
		end
		table.insert(output, string.format("%2d %5d %s", balance, line_number, line))
	end

	local function show_result(lines)
		vim.cmd("topleft vertical new")
		local win = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_width(win, M.config.width)
		local buf = vim.api.nvim_get_current_buf()
		vim.bo[buf].buftype = "nofile"
		vim.bo[buf].bufhidden = "wipe"
		vim.bo[buf].swapfile = false
		vim.bo[buf].modifiable = true
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
		vim.bo[buf].modifiable = true
		vim.bo[buf].buflisted = false
		vim.api.nvim_buf_set_name(buf, "Match Delimiter")
	end

	show_result(output)
end

function match_round()
	return match_delimiter("(", ")", M.config.ignored_ts_nodes)
end

function match_square()
	return match_delimiter("[", "]",M.config.ignored_ts_nodes)
end

function match_curly()
	return match_delimiter("{", "}", M.config.ignored_ts_nods)
end

M.setup = function(opts)
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})

    if M.config.mappings.round then
        vim.keymap.set({ "n", "x" }, M.config.mappings.round, match_round, { desc = "Match round brackets" })
    end
    if M.config.mappings.square then
        vim.keymap.set({ "n", "x" }, M.config.mappings.square, match_square, { desc = "Match square brackets" })
    end
    if M.config.mappings.curly then
        vim.keymap.set({ "n", "x" }, M.config.mappings.curly, match_curly, { desc = "Match curly brackets" })
    end
end

return M
