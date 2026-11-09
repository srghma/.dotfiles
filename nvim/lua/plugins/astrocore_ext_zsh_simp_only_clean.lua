local function register_buffer_command_and_keymap(bufnr, opts)
  vim.keymap.set("n", opts.keymap, opts.fn, {
    buffer = bufnr,
    desc = opts.desc,
  })

  vim.api.nvim_buf_create_user_command(0, opts.command, opts.fn, {
    desc = opts.desc,
  })
end

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    -----------------------------------
    autocmds = {
      remove_lean_comments_cmd = {
        {
          event = "FileType",
          pattern = "zsh",
          callback = function(args)
            register_buffer_command_and_keymap(args.buf, {
              keymap = "<leader>lC",
              command = "CleanLeanSimp",
              desc = "Will clean simp suggestion",

              fn = function()
                local bufnr = vim.api.nvim_get_current_buf()
                local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
                local full_text = table.concat(lines, "\n")

                local seen = {}
                local items = {}

                -- Pattern explanation:
                -- %[apply%]%s*simp only%s*%[(.-)%]
                -- Finds [apply] simp only [...], capturing the content inside the second set of []
                for block in full_text:gmatch "%[apply%]%s*simp only%s*%[(.-)%]" do
                  -- Split by comma (handles newlines inside the block automatically)
                  for part in block:gmatch "[^,]+" do
                    local cleaned = vim.trim(part)
                    if cleaned ~= "" and not seen[cleaned] then
                      seen[cleaned] = true
                      table.insert(items, cleaned)
                    end
                  end
                end

                if #items == 0 then
                  vim.notify("No simp only suggestions found", vim.log.levels.WARN)
                  return
                end

                -- Remove "Try this:" and the [apply] blocks from the buffer
                -- We use vim.cmd for a clean global removal of those specific patterns
                vim.cmd [[silent! g/^Try this:$/d]]
                vim.cmd [[silent! g/^\[apply\] simp only \[.*\]/d]] -- Handles single line
                -- Handle potential multi-line blocks that might remain
                vim.cmd [[silent! g/^\[apply\]/d]]
                vim.cmd [[silent! g/^  .*\]$/d]]

                -- Prepare the result
                local result = "[" .. table.concat(items, ", ") .. "]"

                -- Put it at the current cursor position
                vim.api.nvim_put({ result }, "l", true, true)

                vim.notify("Cleaned " .. #items .. " unique simp items", vim.log.levels.INFO)
              end,
            })
          end,
        },
      },
    },
  },
}
