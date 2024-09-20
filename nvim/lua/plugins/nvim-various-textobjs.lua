local innerOuterMaps = {
	number = "n",
	value = "v",
	key = "k",
	subword = "S", -- lowercase taken for sentence textobj
	notebookCell = "N",
	closedFold = "z", -- z is the common prefix for folds
	chainMember = "m",
	lineCharacterwise = "l",
	-- greedyOuterIndentation = "g",
	anyQuote = "q",
	anyBracket = "o",
}

local oneMaps = {
	-- nearEoL = "n", -- does override the builtin "to next search match" textobj, but nobody really uses that
	-- visibleInWindow = "gw",
	-- toNextClosingBracket = "C", -- % has a race condition with vim's builtin matchit plugin
	-- toNextQuotationMark = "Q",
	-- restOfParagraph = "r",
	-- restOfIndentation = "R",
	-- restOfWindow = "gW",
	-- diagnostic = "!",
	column = "|",
	entireBuffer = "gG", -- G + gg
	url = "L", -- gu, gU, and U would conflict with gugu, gUgU, and gUU. u would conflict with gcu (undo comment)
	-- lastChange = "g;", -- consistent with g; movement
}

local ftMaps = {
	{ map = { mdlink = "l" }, fts = { "markdown", "toml" } },
	{ map = { mdEmphasis = "e" }, fts = { "markdown" } },
	{ map = { pyTripleQuotes = "y" }, fts = { "python" } },
	{ map = { mdFencedCodeBlock = "C" }, fts = { "markdown" } },
	-- stylua: ignore
	-- { map = { doubleSquareBrackets = "D" }, fts = { "lua", "norg", "sh", "fish", "zsh", "bash", "markdown" } },
	{ map = { cssSelector = "c" }, fts = { "css", "scss" } },
	-- { map = { cssColor = "#" }, fts = { "css", "scss" } },
	-- { map = { shellPipe = "P" }, fts = { "sh", "bash", "zsh", "fish" } },
	{ map = { htmlAttribute = "x" }, fts = { "html", "css", "scss", "xml", "vue" } },
}

return {
  -- "chrisgrieser/nvim-various-textobjs",
  dir = "~/projects/nvim-various-textobjs",
  event = "User AstroFile",
  -- event = "BufRead",
  config = function()
	  for objName, map in pairs(oneMaps) do
		  vim.keymap.set(
			  { "o", "x" },
			  map,
			  "<cmd>lua require('various-textobjs')." .. objName .. "()<CR>",
			  { desc = objName .. " textobj" }
		  )
	  end

	  for objName, map in pairs(innerOuterMaps) do
		  local name = " " .. objName .. " textobj"
		  vim.keymap.set(
			  { "o", "x" },
			  "a" .. map,
			  "<cmd>lua require('various-textobjs')." .. objName .. "('outer')<CR>",
			  { desc = "outer" .. name }
		  )
		  vim.keymap.set(
			  { "o", "x" },
			  "i" .. map,
			  "<cmd>lua require('various-textobjs')." .. objName .. "('inner')<CR>",
			  { desc = "inner" .. name }
		  )
	  end

	  local group = vim.api.nvim_create_augroup("VariousTextobjs", {})
	  for _, textobj in pairs(ftMaps) do
		  vim.api.nvim_create_autocmd("FileType", {
			  group = group,
			  pattern = textobj.fts,
			  callback = function()
				  for objName, map in pairs(textobj.map) do
					  local name = " " .. objName .. " textobj"
					  -- stylua: ignore start
					  vim.keymap.set( { "o", "x" }, "a" .. map, ("<cmd>lua require('various-textobjs').%s('%s')<CR>"):format(objName, "outer"), { desc = "outer" .. name, buffer = true })
					  vim.keymap.set( { "o", "x" }, "i" .. map, ("<cmd>lua require('various-textobjs').%s('%s')<CR>"):format(objName, "inner"), { desc = "inner" .. name, buffer = true })
					  -- stylua: ignore end
				  end
			  end,
		  })
	  end

    vim.keymap.set(
	    { "o", "x" },
	    "ii",
	    '<cmd>lua require("various-textobjs").indentation("inner", "inner", "noBlanks")<CR>'
    )

    vim.keymap.set(
	    { "o", "x" },
	    "ai",
	    '<cmd>lua require("various-textobjs").indentation("inner", "inner")<CR>'
    )

    vim.keymap.set(
	    { "n", "x" },
	    "K",
	    '<cmd>lua require("various-textobjs.movements").go_to_indentation("top", "inner", "inner", "withBlanks")<CR>',
      { desc = "go to top of indentation" }
    )
    vim.keymap.set(
	    { "n", "x" },
	    "J",
	    '<cmd>lua require("various-textobjs.movements").go_to_indentation("bottom", "inner", "inner", "withBlanks")<CR>',
      { desc = "go to bottom of indentation" }
    )
    vim.keymap.set(
	    { "n", "x" },
	    "<C-M-k>",
	    '<cmd>lua require("various-textobjs.movements").go_to_indentation("top", "inner", "inner", "noBlanks")<CR>',
      { desc = "go to top of indentation (stop on blank line)" }
    )
    vim.keymap.set(
	    { "n", "x" },
	    "<C-M-j>",
	    '<cmd>lua require("various-textobjs.movements").go_to_indentation("bottom", "inner", "inner", "noBlanks")<CR>',
      { desc = "go to bottom of indentation (stop on blank line)" }
    )
  end,
}
