local shared_clipboard_mappings = {
  -- Paste from system clipboard
  ["p"] = '"+p',
  ["P"] = '"+P',
  -- Copy from system clipboard
  ["y"] = '"+y',
  ["Y"] = '"+y$',
  -- Delete and yank mappings
  [",d"] = '"+d',
  [",D"] = '"+D',
}

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    mappings = {
      v = shared_clipboard_mappings,
      n = shared_clipboard_mappings,
    },
  },
}
