-- https://github.com/AstroNvim/astrocommunity/blob/main/lua/astrocommunity/syntax/vim-easy-align/init.lua
return {
  "junegunn/vim-easy-align",
  event = "User AstroFile",
  keys = {
    { "ga", "<Plug>(EasyAlign)", mode = "x", desc = "EasyAlign (visual)" },
    { "ga", "<Plug>(EasyAlign)", mode = "n", desc = "EasyAlign (normal)" },
  },
}
