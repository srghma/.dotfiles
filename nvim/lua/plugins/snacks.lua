return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      -- opts.picker = opts.picker or {}
      opts.picker.layout = vim.tbl_deep_extend("force", opts.picker.layout or {}, {
        fullscreen = true,
      })
      -- opts.picker.toggles = vim.tbl_deep_extend("force", opts.picker.toggles or {}, {
      --   ignorecase = { icon = "I", value = false },
      -- })

      -- Add to input window
      opts.picker.win = opts.picker.win or {}
      opts.picker.win.input = opts.picker.win.input or {}
      opts.picker.win.input.keys = vim.tbl_deep_extend("force", opts.picker.win.input.keys or {}, {
        ["<M-r>"] = { "toggle_regex", mode = { "i", "n" } },
        ["<M-i>"] = { "toggle_ignorecase", mode = { "i", "n" } },
      })

      -- Add to list window
      opts.picker.win.list = opts.picker.win.list or {}
      opts.picker.win.list.keys = vim.tbl_deep_extend("force", opts.picker.win.list.keys or {}, {
        ["<M-r>"] = "toggle_regex",
        ["<M-i>"] = "toggle_ignorecase",
      })

      return opts
    end,
  },
}

-- return {
-- {
--   "folke/snacks.nvim",
--   opts = function(_, opts)
--     -- Method 1: Follow AstroNvim pattern exactly
--     opts.picker = opts.picker or {}
--
--     -- Add custom grep configuration
--     -- opts.picker.grep = vim.tbl_deep_extend("force", opts.picker.grep or {}, {
--     --   toggle_regex = function(picker, item)
--     --     local picker_opts = picker.opts --[[@as snacks.picker.grep.Config]]
--     --     picker_opts.regex = not picker_opts.regex
--     --     picker:find()
--     --   end,
--     --   keymaps = {
--     --     ["<M-r>"] = "toggle_regex",
--     --   },
--     -- })
--
--     -- -- Method 2: Alternative using pickers (plural) as in your original
--     opts.pickers = opts.pickers or {}
--     opts.pickers.grep = vim.tbl_deep_extend("force", opts.pickers.grep or {}, {
--       toggle_regex = function(picker, item)
--         local picker_opts = picker.opts --[[@as snacks.picker.grep.Config]]
--         picker_opts.regex = not picker_opts.regex
--         picker:find()
--       end,
--       keymaps = {
--         ["<M-r>"] = "toggle_regex",
--       },
--     })
--
--     return opts
--   end,
-- },
-- }
