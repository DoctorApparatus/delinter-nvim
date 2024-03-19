-- typescriptreact/init.lua
local function addTypePropToButton(bufnr, row, col, message)
	-- Ensure Treesitter is available
	local has_ts, ts = pcall(require, "vim.treesitter")
	if not has_ts then
		print("Tree-sitter is not available.")
		return
	end

	local parsers = require("nvim-treesitter.parsers")
	local query = require("vim.treesitter.query")

	local parser = parsers.get_parser(bufnr, "typescriptreact")
	if not parser then
		print("Failed to get Tree-sitter parser for typescriptreact.")
		return
	end

	local root_tree = parser:parse()[1]:root()
	local root_start_row, _, root_end_row, _ = root_tree:range()

	-- Define Tree-sitter query to find button elements without a type attribute
	local ts_query = [[
    (jsx_element
      (jsx_opening_element
        name: (identifier) @tag
        (jsx_attribute
          name: (property_identifier) @attr_name
          value: (string) @attr_value)?
        )+
      ) @element
    )
    ]]

	-- Prepare the query
	local query_obj = ts.parse_query("typescriptreact", ts_query)

	-- Iterate over all matches
	for _, match, _ in query_obj:iter_matches(root_tree, bufnr, root_start_row, root_end_row + 1) do
		local tag_node = match.tag
		if tag_node and query.get_node_text(tag_node, bufnr) == "button" then
			-- Check if the type attribute is missing
			local has_type_attr = false
			for id, node in pairs(match) do
				if query.get_node_text(node, bufnr) == "type" then
					has_type_attr = true
					break
				end
			end
			if not has_type_attr then
				-- Add type="button" attribute
				local start_row, start_col, end_row, end_col = tag_node:range()
				vim.api.nvim_buf_set_text(bufnr, start_row, end_col, start_row, end_col, { ' type="button"' })
			end
		end
	end
end

return {
	["Provide an explicit type prop for the button element."] = {
		options = {
			addTypeProp = addTypePropToButton,
		},
		preferred = "addTypeProp",
	},
}
