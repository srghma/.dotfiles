return {
  "echasnovski/mini.align",
  event = "User AstroFile",
  opts = {
    mappings = {
      start = '',
      start_with_preview = 'ga',
    },
  },
  specs = {
    {
      "catppuccin",
      optional = true,
      ---@type CatppuccinOptions
      opts = { integrations = { mini = true } },
    },
  },
}
