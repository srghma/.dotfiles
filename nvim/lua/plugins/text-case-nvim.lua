-- like vim abolish
return {
  "johmsalas/text-case.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
  config = function()
    require("textcase").setup({
      prefix = "<leader>c"
    })
    require("telescope").load_extension("textcase")
  end,
  keys = {
    "<leader>c",
    { "<leader>c.", "<cmd>TextCaseOpenTelescope<CR>", mode = { "n", "x" }, desc = "Telescope" },
    -- { "<leader>ca", "<cmd>TextCaseOpenTelescopeQuickChange<CR>", mode = { "n" }, desc = "Telescope Quick Change" }, -- same
    -- { "<leader>ci", "<cmd>TextCaseOpenTelescopeLSPChange<CR>", mode = { "n" }, desc = "Telescope LSP Change" }, -- doesnt work
  },
  cmd = {
    -- NOTE: The Subs command name can be customized via the option "substitude_command_name"
    "Subs", -- !!!!!
    "TextCaseOpenTelescope",
    "TextCaseOpenTelescopeQuickChange",
    "TextCaseOpenTelescopeLSPChange",
    "TextCaseStartReplacingCommand",
  },
  -- If you want to use the interactive feature of the `Subs` command right away, text-case.nvim
  -- has to be loaded on startup. Otherwise, the interactive feature of the `Subs` will only be
  -- available after the first executing of it or after a keymap of text-case.nvim has been used.
  lazy = false,
}
