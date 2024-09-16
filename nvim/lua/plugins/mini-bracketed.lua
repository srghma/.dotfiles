return {
  "echasnovski/mini.bracketed",
  event = "User AstroFile",
  opts = {
    buffer     = { suffix = 'bb', options = {} },
    comment    = { suffix = 'bc', options = {} },
    conflict   = { suffix = 'bx', options = {} },
    diagnostic = { suffix = 'bd', options = {} },
    file       = { suffix = 'bf', options = {} },
    indent     = { suffix = 'bi', options = {} },
    jump       = { suffix = 'bj', options = {} },
    location   = { suffix = 'bl', options = {} },
    oldfile    = { suffix = 'bo', options = {} },
    quickfix   = { suffix = 'bq', options = {} },
    treesitter = { suffix = 'bt', options = {} },
    undo       = { suffix = 'bu', options = {} },
    window     = { suffix = 'bw', options = {} },
    yank       = { suffix = 'by', options = {} },
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
