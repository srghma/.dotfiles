-- return { "digama0/mm0", rtp = "vim" }
return {
  {
    "digama0/mm0",
    -- rtp = "vim",
    dir = "/home/srghma/projects/mm0/vim",
  },
  {
    "AstroNvim/astrolsp",
    ---@type AstroLSPOpts
    opts = {
      servers = {
        "mm0_ls",
      },
      config = {
        mm0_ls = {
          cmd = { "/home/srghma/mm0-debug.sh" },
          -- cmd = { "mm0-rs", "server", "-d" },
          filetypes = { "metamath-zero" },
          root_dir = require("lspconfig.util").root_pattern(".git"),
          single_file_support = true,
          -- FIX: Send an empty object so the server doesn't panic on 'null'
          init_options = vim.empty_dict(),
        },
      },
    },
  }
}
