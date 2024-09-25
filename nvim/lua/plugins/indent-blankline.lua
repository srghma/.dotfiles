return {
  "lukas-reineke/indent-blankline.nvim",
  event = "User AstroFile",
  cmd = { "IBLEnable", "IBLDisable", "IBLToggle", "IBLEnableScope", "IBLDisableScope", "IBLToggleScope" },
  specs = {
    {
      "AstroNvim/astrocore",
      opts = function(_, opts)
        local maps = opts.mappings
        maps.n["<Leader>u|"] = { "<Cmd>IBLToggle<CR>", desc = "Toggle indent guides" }
      end,
    },
  },
  main = "ibl",
  config = function()
    local highlight = {
      "RainbowRed",
      "RainbowYellow",
      "RainbowBlue",
      "RainbowOrange",
      "RainbowGreen",
      "RainbowViolet",
      "RainbowCyan",
    }

    local hooks = require "ibl.hooks"
    -- create the highlight groups in the highlight setup hook, so they are reset
    -- every time the colorscheme changes
    hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
      vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#8B4648" })     -- Darker Red
      vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#9A8354" })  -- Darker Yellow
      vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#4A6A8D" })    -- Darker Blue
      vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#815C42" })  -- Darker Orange
      vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#4F7047" })   -- Darker Green
      vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#7A608B" })  -- Darker Violet
      vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#4B6D71" })    -- Darker Cyan
    end)

    require("ibl").setup {
      indent = { char = "▏", highlight = highlight },
      scope = { show_start = false, show_end = false },
      exclude = {
        buftypes = {
          "nofile",
          "prompt",
          "quickfix",
          "terminal",
        },
        filetypes = {
          "aerial",
          "alpha",
          "dashboard",
          "help",
          "lazy",
          "mason",
          "neo-tree",
          "NvimTree",
          "neogitstatus",
          "notify",
          "startify",
          "toggleterm",
          "Trouble",
        },
      }
    }
  end
}
