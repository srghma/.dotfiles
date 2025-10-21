return {
  "echasnovski/mini.move",
  event = "User AstroFile",
  opts = {
    mappings = {
      left  = '<',
      right = '>',
      down  = ']e',
      up    = '[e',

      line_left  = '',
      line_right = '',
      line_down  = ']e',
      line_up    = '[e',
    }
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
