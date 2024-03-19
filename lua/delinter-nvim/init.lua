local M = {}

M.default_config = {
	-- Default empty configuration; specific filetype actions will be loaded dynamically
	filetype_actions = {},
}

M.config = {}

function M.setup(user_config)
	M.config = vim.tbl_deep_extend("force", M.default_config, user_config or {})

	-- Debugging enabled/disabled message
	if M.config.debug then
		M.debug_msg("Debugging is enabled.")
	else
		M.debug_msg("Debugging is disabled. To enable, set debug = true in the plugin config.")
	end

	for _, filetype in ipairs(M.config.filetypes or {}) do
		local ok, actions = pcall(require, "delinter-nvim.filetypes." .. filetype)
		if ok then
			if type(actions) == "table" then
				M.config.filetype_actions[filetype] = actions
				M.debug_msg("Actions correctly loaded and structured for filetype: " .. filetype)
			else
				M.debug_msg(
					"Loaded actions for filetype: " .. filetype .. " have incorrect structure: " .. type(actions)
				)
			end
		else
			M.debug_msg("Failed to load actions for filetype: " .. filetype)
		end
	end

	-- Check for Tree-sitter and required parsers installation
	local parsers = require("nvim-treesitter.parsers")
	local missing_parsers = {}

	for _, filetype in ipairs(M.config.filetypes or {}) do
		local parser_name = filetype -- Assume filetype matches parser name; adjust if necessary
		-- Special handling for typescriptreact -> tsx parser
		if filetype == "typescriptreact" then
			parser_name = "tsx"
		end

		if not parsers.has_parser(parser_name) then
			table.insert(missing_parsers, parser_name)
		end
	end

	if #missing_parsers > 0 then
		M.debug_msg("Missing Tree-sitter parsers for: " .. table.concat(missing_parsers, ", "))
		M.debug_msg("Please install missing parsers using :TSInstall " .. table.concat(missing_parsers, " :TSInstall "))
	else
		M.debug_msg("All required Tree-sitter parsers are installed.")
	end
end

function M.register_actions(filetype, diagnostic_actions)
	if not M.config.filetype_actions[filetype] then
		M.config.filetype_actions[filetype] = {}
	end

	for diagnostic, info in pairs(diagnostic_actions) do
		if not M.config.filetype_actions[filetype][diagnostic] then
			M.config.filetype_actions[filetype][diagnostic] = { options = {}, preferred = nil }
		end

		for identifier, action in pairs(info.options) do
			M.config.filetype_actions[filetype][diagnostic].options[identifier] = action
		end

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

function M.list_enabled_filetypes()
	print("Enabled filetypes for diagnostic actions:")
	for filetype, _ in pairs(M.config.filetype_actions) do
		print("- " .. filetype)
	end
end

function M.list_diagnostic_actions_for_filetype(filetype)
	local actions = M.config.filetype_actions[filetype]
	if not actions then
		print("No diagnostic actions available for filetype: " .. filetype)
		return
	end

	print("Available diagnostic actions for filetype: " .. filetype)
	for diagnostic, info in pairs(actions) do
		local action_identifiers = {}
		for identifier, _ in pairs(info.options) do
			table.insert(action_identifiers, identifier)
		end
		print(string.format("- %s: %s", diagnostic, table.concat(action_identifiers, ", ")))
	end
end

function string.trim(s)
	return s:match("^%s*(.*%S)") or ""
end

function M.execute_action_at_cursor()
	local bufnr = vim.api.nvim_get_current_buf()
	local filetype = vim.bo[bufnr].filetype
	-- Ensure actions for the filetype are a table
	if type(M.config.filetype_actions[filetype]) ~= "table" then
		M.debug_msg("No actions configured for filetype: " .. filetype .. " or actions are misconfigured.")
		return
	end

	local actions = M.config.filetype_actions[filetype]
	local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
	row = row - 1 -- Adjust to 0-based indexing

	local diagnostics = vim.diagnostic.get(bufnr, { lnum = row })
	if #diagnostics == 0 then
		M.debug_msg("No diagnostics found at cursor position.")
		return
	end

	local found_action = false
	for _, diag in ipairs(diagnostics) do
		-- Normalize the diagnostic message
		local normalizedDiagMsg = string.trim(diag.message)
		for diagnostic, info in pairs(actions) do
			if normalizedDiagMsg == diagnostic or string.find(normalizedDiagMsg, diagnostic) then
				local preferred_action = info.preferred
				if info.options and info.options[preferred_action] then
					local action = info.options[preferred_action]
					if action then
						-- Ensure action functions use 1-based indexing for rows
						action(bufnr, row + 1, _, normalizedDiagMsg)
						M.debug_msg("Executed action: " .. preferred_action .. " for diagnostic: " .. normalizedDiagMsg)
						found_action = true
						break -- Assuming one action per diagnostic is sufficient
					end
				else
					M.debug_msg(
						"Preferred action '"
							.. tostring(preferred_action)
							.. "' for '"
							.. normalizedDiagMsg
							.. "' not found."
					)
				end
			end
		end
		if found_action then
			break
		end
	end

	if not found_action then
		M.debug_msg("No specific actions available for diagnostics at cursor position.")
	end
end

function M.check_diagnostic_action_at_cursor()
	local bufnr = vim.api.nvim_get_current_buf()
	local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
	row = row - 1 -- Convert to 0-based indexing

	local diagnostics = vim.diagnostic.get(bufnr, { lnum = row })
	if #diagnostics == 0 then
		print("No diagnostics found at cursor position.")
		return
	end

	local filetype = vim.bo[bufnr].filetype
	if type(M.config.filetype_actions) ~= "table" or not M.config.filetype_actions[filetype] then
		print("No diagnostic actions configured for filetype: " .. filetype)
		return
	end

	local actions_for_filetype = M.config.filetype_actions[filetype]
	local found_action = false
	for _, diag in ipairs(diagnostics) do
		for diagnostic, info in pairs(actions_for_filetype) do
			-- Ensure that 'info' and 'info.options' are tables before proceeding
			if type(info) == "table" and type(info.options) == "table" and string.match(diag.message, diagnostic) then
				local action_names = {}
				for name, _ in pairs(info.options) do
					table.insert(action_names, name)
				end
				print(
					"Diagnostic action(s) available for '" .. diag.message .. "': " .. table.concat(action_names, ", ")
				)
				found_action = true
				break
			end
		end
	end

	if not found_action then
		print("No specific actions available for diagnostics at cursor position.")
	end
end

function M.debug_msg(...)
	if M.config.debug then
		print(...)
	end
end

return M
