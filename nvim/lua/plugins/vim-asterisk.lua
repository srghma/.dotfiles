-- return {
--   'haya14busa/vim-asterisk',                              -- improved * search
--   lazy = true,
--   event = { 'BufReadPost', 'BufAdd', 'BufNewFile' },
--   config = function()
--     vim.g["asterisk#keeppos"] = 1
--     vim.keymap.set('n', "*",  "<Plug>(asterisk-z*)<CR>")
--     -- vim.keymap.set('n', "#",  "<Plug>(asterisk-z#)")
--     vim.keymap.set('n', "g*", "<Plug>(asterisk-gz*)<CR>")
--     -- vim.keymap.set('n', "g#", "<Plug>(asterisk-gz#)")
--   end
-- }

---@type LazySpec
return {
  'rapan931/lasterisk.nvim',                              -- improved * search
  lazy = true,
  event = { 'BufReadPost', 'BufAdd', 'BufNewFile' },
  config = function()
    vim.keymap.set('n', '*',  function() require("lasterisk").search() end)
    vim.keymap.set('n', 'g*', function() require("lasterisk").search({ is_whole = false }) end)
    vim.keymap.set('x', '*',  function() require("lasterisk").search({ is_whole = false }) end)
  end
}
