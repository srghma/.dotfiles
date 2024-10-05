-- ---@type LazySpec
-- return {
--   "echasnovski/mini.trailspace",
--   event = "VeryLazy",
--   init = function()
--       vim.api.nvim_create_autocmd("BufWrite", {
--           callback = function()
--               MiniTrailspace.trim()
--               MiniTrailspace.trim_last_lines()
--           end
--       })
--
--       -- Disable for Lazy Window
--       vim.api.nvim_create_autocmd("FileType", {
--           pattern = "lazy",
--           callback = function(data)
--               vim.b[data.buf].minitrailspace_disable = true
--               vim.api.nvim_buf_call(data.buf, MiniTrailspace.unhighlight)
--           end,
--       })
--   end,
--   opts = {}
-- }

return {
  'echasnovski/mini.trailspace',
  event = { 'BufReadPre', 'BufNewFile' },
  config = function()
    vim.cmd [[hi MiniTrailspace guibg=#b58900]]

    require('mini.trailspace').setup()

    -- -- trim any leftover whitespace if conform has not been able to do so
    -- vim.api.nvim_create_autocmd({ 'BufWrite' }, {
    --   callback = function()
    --     require('mini.trailspace').trim()
    --   end,
    -- })

		-- local trailspace = require("mini.trailspace")
		-- trailspace.setup()
		-- vim.api.nvim_create_autocmd("BufWritePre", {
		-- 	group = vim.api.nvim_create_augroup("trim-whitespace", { clear = true }),
		-- 	callback = function()
		-- 		trailspace.trim()
		-- 		trailspace.trim_last_lines()
		-- 	end,
		-- })
  end,
}
