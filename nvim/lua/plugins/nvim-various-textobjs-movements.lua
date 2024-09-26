return {
  dir = "/home/srghma/projects/nvim-various-textobjs-movements",
  event = "User AstroFile",
	config = function ()
		require("various-textobjs-movements").setup({
			go_to_indentation_top_withBlanks = "K",
			go_to_indentation_bottom_withBlanks = "J",
			go_to_indentation_top_noBlanks = "<C-M-k>",
			go_to_indentation_bottom_noBlanks = "<C-M-j>",
		})
	end,
}
