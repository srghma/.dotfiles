return {
  {
    "srghma-backup/nvim-various-textobjs-movements",
    -- dir = "/home/srghma/projects/nvim-various-textobjs-movements",
    event = "User AstroFile",
	  opts = {}, -- required
  },
  {
    "AstroNvim/astrocore",
    opts = {
      mappings = {
        n = {
          ["K"] = '', -- disables
          ["H"] = ':lua vim.lsp.buf.hover()<CR>', -- before was K
        },
      },
    },
  },
}
