local bufnr = vim.api.nvim_get_current_buf()

-- fixes
--
-- :map ,v
-- n  ,v           @<Plug>(LeanInfoviewViewOptions)
--                  Change the infoview view options.
-- n  ,v          * <Cmd>vsplit<CR>
--                  Vertical Split
--
-- :map ,s
-- n  ,s           @<Plug>(LeanInfoviewAcceptSuggestion)
--                  Accept the first infoview suggestion.
-- n  ,s          * <Cmd>split<CR>
--                  Horizontal Split
--
-- makes
-- [",v"] = { "<Cmd>vsplit<CR>", desc = "Vertical Split" },
-- [",s"] = { "<Cmd>split<CR>", desc = "Horizontal Split" },
--
-- work again
local function safe_del(mode, lhs) pcall(vim.keymap.del, mode, lhs, { buffer = bufnr }) end

safe_del("n", ",s")
safe_del("n", ",v")

vim.keymap.set("n", ",is", "<Plug>(LeanInfoviewAcceptSuggestion)", {
  buffer = bufnr,
  silent = true,
  desc = "Accept the first infoview suggestion",
})

vim.keymap.set("n", ",iv", "<Plug>(LeanInfoviewViewOptions)", {
  buffer = bufnr,
  silent = true,
  desc = "Change the infoview view options",
})
