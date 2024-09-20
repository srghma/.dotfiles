-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  -- { import = "astrocommunity.pack.lua" },
  { import = "astrocommunity.pack.typescript" },
  { import = "astrocommunity.pack.nix" },
  { import = "astrocommunity.bars-and-lines.vim-illuminate" },
  -- { import = "astrocommunity.pack.haskell" },
  { import = "astrocommunity.pack.rust" },
  { import = "astrocommunity.motion.nvim-spider" },
  { import = "astrocommunity.editing-support.rainbow-delimiters-nvim" },
  { import = "astrocommunity.editing-support.auto-save-nvim" },
  -- { import = "astrocommunity.motion.nvim-spider" },
  -- { import = "astrocommunity.indent.mini-indentscope" },
  -- import/override with your plugins folder
}

-- highlight IlluminatedWordWrite gui=underline
-- highlight IlluminatedWordRead gui=underline
-- highlight IlluminatedWordText gui=underline
