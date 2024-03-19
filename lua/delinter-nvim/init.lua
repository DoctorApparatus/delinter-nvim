local M = {}

M.default_config = {
	filetype_actions = {},
}

M.config = {}

function M.setup(user_config)
	-- Load default configurations
	local filetypes = { "lua" } -- Extend this list as needed
	for _, filetype in ipairs(filetypes) do
		local ok, actions = pcall(require, "delinter-nvim." .. filetype)
		if ok then
			M.default_config.filetype_actions[filetype] = actions
		end
	end

	-- Apply user configurations
	M.config = vim.tbl_deep_extend("force", M.default_config, user_config or {})
end

function M.register_actions(filetype, diagnostic_actions)
	if not M.config.filetype_actions[filetype] then
		M.config.filetype_actions[filetype] = {}
	end

	for diagnostic, info in pairs(diagnostic_actions) do
		-- Ensure a consistent structure for diagnostic information
		if not M.config.filetype_actions[filetype][diagnostic] then
			M.config.filetype_actions[filetype][diagnostic] = { options = {}, preferred = nil }
		end

		for identifier, action in pairs(info.options) do
			M.config.filetype_actions[filetype][diagnostic].options[identifier] = action
		end

		-- Allow setting a preferred action upon registration
		if info.preferred then
			M.config.filetype_actions[filetype][diagnostic].preferred = info.preferred
		end
	end
end

function M.set_preferred_action(filetype, diagnostic, preferred_identifier)
	local diag_conf = M.config.filetype_actions[filetype] and M.config.filetype_actions[filetype][diagnostic]
	if diag_conf then
		if diag_conf.options[preferred_identifier] then
			diag_conf.preferred = preferred_identifier
		else
			print(
				"Action identifier '"
					.. preferred_identifier
					.. "' not found for '"
					.. diagnostic
					.. "' in filetype '"
					.. filetype
					.. "'"
			)
		end
	else
		print("No actions registered for '" .. diagnostic .. "' in filetype '" .. filetype .. "'")
	end
end

function M.execute_action_at_cursor()
	local bufnr = vim.api.nvim_get_current_buf()
	local filetype = vim.bo[bufnr].filetype
	local actions = M.config.filetype_actions[filetype]
	if not actions then
		print("No actions configured for filetype: " .. filetype)
		return
	end

	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	row = row - 1 -- Adjust to 0-based indexing

	local diagnostics = vim.diagnostic.get(bufnr, { lnum = row })
	if #diagnostics == 0 then
		print("No diagnostics found at cursor position.")
		return
	end

	for _, diag in ipairs(diagnostics) do
		local diagnostic_actions = actions[diag.message]
		if diagnostic_actions then
			local preferred_action = diagnostic_actions.preferred
			local action = diagnostic_actions.options[preferred_action]
			if action then
				action(bufnr, row, col, diag.message)
				return
			else
				print("Preferred action '" .. preferred_action .. "' for '" .. diag.message .. "' not found.")
			end
		end
	end
end

return M
