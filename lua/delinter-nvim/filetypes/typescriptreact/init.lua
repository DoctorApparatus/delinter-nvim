local function addTypeAttributeToAllButtons(bufnr)
	local ts = require("vim.treesitter")
	local query = require("vim.treesitter.query")
	local parser = ts.get_parser(bufnr, "tsx")
	local tree = parser:parse()[1]

	local query_str = [[
    (jsx_opening_element
      name: (identifier) @element_name
      (#eq? @element_name "button")
    ) @target
    ]]

	-- Prepare and run the query.
	local tsquery = query.parse("tsx", query_str)
	for _, node in tsquery:iter_captures(tree:root(), bufnr, 0, -1) do
		local _, _, e_row, e_col = node:range()
		-- Find the position just before '>'
		local line = vim.api.nvim_buf_get_lines(bufnr, e_row, e_row + 1, false)[1]
		local insert_pos = line:find(">", nil, true) or #line
		-- Prepare the text to insert.
		local insert_text = ' type="button"'
		-- Insert the text.
		vim.api.nvim_buf_set_text(bufnr, e_row, insert_pos - 1, e_row, insert_pos - 1, { insert_text })
	end
end

return {
	["Provide an explicit type prop for the button element."] = {
		options = {
			addTypeProp = addTypeAttributeToAllButtons,
		},
		preferred = "addTypeProp",
	},
}
