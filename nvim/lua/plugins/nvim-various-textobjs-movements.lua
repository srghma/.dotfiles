return {
  {
    "srghma/nvim-various-textobjs-movements",
    -- dir = "/home/srghma/projects/nvim-various-textobjs-movements",
    event = "User AstroFile",
	  opts = {}, -- required
  },
  {
    "AstroNvim/astrocore",
    opts = {
      mappings = {
        n = {
          ["H"] = ':lua vim.lsp.buf.hover()<CR>',
        },
      },
    },
  },
}
