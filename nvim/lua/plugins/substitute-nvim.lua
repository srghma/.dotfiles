return {
  {
    "gbprod/substitute.nvim",
    opts = {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
    },
    dependencies = {
      {
        "AstroNvim/astrocore",
        opts = {
          mappings = {
            x = {
              ["X"] = {
                function() return require('substitute.exchange').visual() end,
                desc = "Exchange selection",
              },
              -- ["gx"] = {
              --   function() return require('substitute').visual() end,
              --   noremap = true,
              --   desc = "Substitute selection",
              -- },
            },
            n = {
              ["cx"] = {
                function() return require('substitute.exchange').operator() end,
                noremap = true,
                desc = "Exchange operator",
              },
              ["cxx"] = {
                function() return require('substitute.exchange').line() end,
                noremap = true,
                desc = "Exchange line",
              },
              -- ["<Ctrl-C>"] = { -- Escape
              --   function() return require('substitute.exchange').cancel() end,
              --   noremap = true,
              --   desc = "Cancel exchange",
              -- },

              -- ["gx"] = {
              --   function() return require('substitute').operator() end,
              --   noremap = true,
              --   desc = "Substitute operator",
              -- },
              -- ["gxx"] = {
              --   function() return require('substitute').line() end,
              --   noremap = true,
              --   desc = "Substitute line",
              -- },
              -- ["gX"] = {
              --   function() return require('substitute').eol() end,
              --   noremap = true,
              --   desc = "Substitute eol",
              -- },
            },
          },
        },
      },
    },
  },
}
