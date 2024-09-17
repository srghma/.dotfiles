return {
  "L3MON4D3/LuaSnip",
  version = nil,
  branch = "master",
  dependencies = { { "rafamadriz/friendly-snippets", lazy = false } },
  config = function(plugin, opts)
    -- include the default astronvim config that calls the setup call
    require("astronvim.plugins.configs.luasnip")(plugin, opts)

    -- Adding JavaScript snippets in typescript files
    require("luasnip").filetype_extend("typescript", { "javascript" })
    require("luasnip").filetype_extend("ruby", {"rails"})

    -- load snippets paths + friendly-snippets (should be last)
    require("luasnip.loaders.from_vscode").lazy_load({
      paths = { vim.fn.stdpath("config") .. "/snippets" },
    })
  end,
}
