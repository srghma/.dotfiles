---@type LazySpec
return {
  {
    "nvim-treesitter/nvim-treesitter",
    init = function()
      vim.treesitter.language.register("lean", { "lean4" })

      vim.api.nvim_create_autocmd("User", {
        pattern = "TSUpdate",
        callback = function()
          require("nvim-treesitter.parsers").lean = {
            install_info = {
              path = "/home/srghma/projects/tree-sitter-lean",
              queries = "queries",
            },
          }
        end,
      })

      -- Disable Treesitter on `.lean` buffers (so lean.nvim + leanls handle them),
      -- while keeping the `lean` parser active for markdown ```lean / ```lean4 blocks.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "lean",
        callback = function(ev)
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(ev.buf) then pcall(vim.treesitter.stop, ev.buf) end
          end)
        end,
      })
    end,
  },
}
