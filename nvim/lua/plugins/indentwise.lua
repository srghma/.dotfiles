vim.g.indentwise_suppress_keymaps = 1

return { 
	'jeetsukumaran/vim-indentwise',
	-- config = function(lazy, opts)
	-- 	vim.g.indentwise_skip_blanks = 1
	-- 	local function indentwise_is_top_level()
	-- 		local first_char = string.sub(vim.fn.getline('.'), 0, 1)
	-- 		return first_char == '' or string.match(first_char, '\\S')
	-- 	end
	-- 	vim.keymap.set(
	-- 		{'n', 'i', 'v'},
	-- 		'K',
	-- 		function()
	-- 			return indentwise_is_top_level() and '{' or  '<Plug>(IndentWiseBlockScopeBoundaryBegin)'
	-- 		end,
	-- 		{silent = true, expr = true}
	-- 	)
	-- 	vim.keymap.set(
	-- 		{'n', 'i', 'v'},
	-- 		'J',
	-- 		function()
	-- 			return indentwise_is_top_level() and '}' or  '<Plug>(IndentWiseBlockScopeBoundaryEnd)'
	-- 		end,
	-- 		{silent = true, expr = true}
	-- 	)
	-- end,
	-- enabled = false,
}
