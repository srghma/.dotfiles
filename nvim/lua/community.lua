-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  -- dir = "/home/srghma/projects/astrocommunity",
  -- { import = "astrocommunity.pack.lua" },
  { import = "astrocommunity.pack.typescript" },
  { import = "astrocommunity.pack.nix" },
  { import = "astrocommunity.bars-and-lines.vim-illuminate" },
  -- { import = "astrocommunity.pack.haskell" },
  { import = "astrocommunity.pack.rust" },
  -- { import = "astrocommunity.pack.purescript" },
  { import = "astrocommunity.motion.nvim-spider" },
  -- { import = "astrocommunity.motion.leap-nvim" },
  { import = "astrocommunity.motion.flash-nvim" },
  { import = "astrocommunity.editing-support.rainbow-delimiters-nvim" },
  -- { import = "astrocommunity.editing-support.auto-save-nvim" },
  {
    "okuuva/auto-save.nvim",
    event = { "User AstroFile", "InsertEnter" },
    opts = {
      trigger_events = { -- See :h events
        immediate_save = { "BufLeave", "TabLeave", "FocusLost", "VimLeavePre" }, -- vim events that trigger an immediate save
        -- defer_save = { "InsertLeave", "TextChanged" }, -- vim events that trigger a deferred save (saves after `debounce_delay`)
        defer_save = {}, -- vim events that trigger a deferred save (saves after `debounce_delay`)
        cancel_deferred_save = { "InsertEnter" }, -- vim events that cancel a pending deferred save
      },
    },
  },
  { import = "astrocommunity.search.nvim-spectre" },
  dofile "/home/srghma/projects/astrocommunity/lua/astrocommunity/pack/purescript/init.lua",
  dofile "/home/srghma/projects/astrocommunity/lua/astrocommunity/pack/idris2/init.lua",

  -- { import = "astrocommunity.pack.purescript" },
  {
    "AstroNvim/astrolsp",
    opts = {
      config = {
        purescriptls = {
          settings = {
            purescript = {
              formatter = "purs-tidy", -- add this to enable purs-tidy formatting on every save
            },
          },
        },
      },
    },
  },

  -- { import = "astrocommunity.editing-support.text-case-nvim" },
  -- { import = "astrocommunity.motion.nvim-spider" },
  -- { import = "astrocommunity.indent.mini-indentscope" },

  { "nvim-treesitter/nvim-treesitter", dir = "/home/srghma/projects/nvim-treesitter" },
  -- { "nvim-treesitter/nvim-treesitter", dev { path = "/home/srghma/projects/nvim-treesitter" }, },

  -- { "kevinhwang91/nvim-ufo", url = "https://github.com/srghma/nvim-ufo.git", rev = "512096fc1644466a99a08cdb9647b729866e88fc" },
  -- cd ~/.local/share/nvim/lazy/nvim-ufo/ && git pull origin main
  { "kevinhwang91/nvim-ufo", rev = "c96bb3bb853ff6253fe74f057df03e61fafd2403" },
  -- { "kevinhwang91/nvim-ufo", branch = "main" },
}
