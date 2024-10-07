---@type LazySpec
return {
  "echasnovski/mini.operators",
  -- keys = function(_, keys)
  --   local plugin = require("lazy.core.config").spec.plugins["mini.operators"]
  --   local opts = require("lazy.core.plugin").values(plugin, "opts", false)
  --   for operator, default in pairs {
  --     -- evaluate = "go=",
  --     -- exchange = "gx",
  --     -- multiply = "gom",
  --     replace = ",r", -- "R" doesnt work
  --     -- sort = "gos",
  --   } do
  --     local prefix = vim.tbl_get(opts, operator, "prefix") or default
  --     local line_lhs = prefix .. vim.fn.strcharpart(prefix, vim.fn.strchars(prefix) - 1, 1)
  --     local name = operator:sub(1, 1):upper() .. operator:sub(2)
  --     vim.list_extend(keys, {
  --       { line_lhs, desc = name .. " line" },
  --       { prefix, desc = name .. " operator" },
  --       { prefix, mode = "x", desc = name .. " selection" },
  --     })
  --   end
  -- end,
  config = function ()
    require('mini.operators').setup({
      -- Each entry configures one operator.
      -- `prefix` defines keys mapped during `setup()`: in Normal mode
      -- to operate on textobject and line, in Visual - on selection.

      -- Evaluate text and replace with output
      evaluate = {
        -- prefix = 'g=',
        prefix = ',=',

        -- Function which does the evaluation
        func = nil,
      },

      -- Exchange text regions
      exchange = {
        -- prefix = 'gx',
        prefix = ',,x',

        -- Whether to reindent new text to match previous indent
        reindent_linewise = true,
      },

      -- Multiply (duplicate) text
      multiply = {
        -- prefix = 'gm',
        prefix = ',,m',

        -- Function which can modify text before multiplying
        func = nil,
      },

      -- Replace text with register
      replace = {
        prefix = ',r',
        -- prefix = false,

        -- Whether to reindent new text to match previous indent
        reindent_linewise = true,
      },

      -- Sort text
      sort = {
        prefix = ',,s',
        -- prefix = false,

        -- Function which does the sort
        func = nil,
      }
    })
  end
  -- opts = {},
}
