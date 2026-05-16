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
          pattern = "lean",
          callback = function(args)
            register_buffer_command_and_keymap(args.buf, {
              keymap = "<leader>lC",
              command = "RemoveLeanComments",
              desc = "Remove all Lean comments",
              fn = function()
                -- Delete line comments
                vim.cmd [[silent! g/^\s*--/d]]
                -- Delete multiline block comments like /- ... -/
                vim.cmd [[silent! g/\/-/,/-\//d]]
                vim.notify("Removed Lean comments", vim.log.levels.INFO)
              end,
            })

            register_buffer_command_and_keymap(args.buf, {
              keymap = "<leader>lK",
              command = "KeepLeanDefinitions",
              desc = "Keep only Lean definitions (def, instance, class, etc.)",
              fn = function()
                vim.cmd [[silent! g!/^.*\<\(def\|instance\|class\|abbrev\|opaque\|extern\|section\|end\|namespace\|inductive\)\>/d]]
                vim.cmd "silent! g/^@\\[\\s\\+extern[^]]\\+\\]\\s*$/join"
                vim.notify("Kept only Lean definitions", vim.log.levels.INFO)
              end,
            })

            register_buffer_command_and_keymap(args.buf, {
              keymap = "<leader>lmI",
              command = "IndentLeanNamespaces",
              desc = "Auto-indent all namespace ... end blocks",
              fn = function()
                -- in current file should
                --
                --
                -- ```
                -- namespace BaseIO
                -- @[extern "lean_io_as_task"] opaque asTask (act : BaseIO α) (prio := Task.Priority.default) : BaseIO (Task α) :=
                -- @[extern "lean_io_map_task"] opaque mapTask (f : α → BaseIO β) (t : Task α) (prio := Task.Priority.default) (sync := false) :
                -- @[extern "lean_io_bind_task"] opaque bindTask (t : Task α) (f : α → BaseIO (Task β)) (prio := Task.Priority.default)
                -- def chainTask (t : Task α) (f : α → BaseIO Unit) (prio := Task.Priority.default)
                -- def mapTasks (f : List α → BaseIO β) (tasks : List (Task α)) (prio := Task.Priority.default)
                -- end BaseIO
                -- ```
                -- to
                -- ```
                -- namespace BaseIO
                --   @[extern "lean_io_as_task"] opaque asTask (act : BaseIO α) (prio := Task.Priority.default) : BaseIO (Task α) :=
                --   @[extern "lean_io_map_task"] opaque mapTask (f : α → BaseIO β) (t : Task α) (prio := Task.Priority.default) (sync := false) :
                --   @[extern "lean_io_bind_task"] opaque bindTask (t : Task α) (f : α → BaseIO (Task β)) (prio := Task.Priority.default)
                --   def chainTask (t : Task α) (f : α → BaseIO Unit) (prio := Task.Priority.default)
                --   def mapTasks (f : List α → BaseIO β) (tasks : List (Task α)) (prio := Task.Priority.default)
                -- end BaseIO
                -- ```
                local function indent_namespaces()
                  local buf = vim.api.nvim_get_current_buf()
                  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
                  local new_lines = {}
                  local indent_level = 0

                  for _i, line in ipairs(lines) do
                    local trimmed = line:match "^%s*(.-)%s*$"

                    -- Check if line starts a namespace
                    if trimmed:match "^namespace%s+" then
                      -- Keep namespace line with current indentation level
                      local current_indent = string.rep("  ", indent_level)
                      table.insert(new_lines, current_indent .. trimmed)
                      -- Increase indent level for content inside this namespace
                      indent_level = indent_level + 1

                      -- Check if line is an end statement (matching namespace or other blocks)
                    elseif trimmed:match "^end%s" or trimmed == "end" then
                      -- Decrease indent level first
                      if indent_level > 0 then indent_level = indent_level - 1 end
                      -- Apply indentation to end statement
                      local current_indent = string.rep("  ", indent_level)
                      table.insert(new_lines, current_indent .. trimmed)

                      -- Regular content line
                    else
                      local current_indent = string.rep("  ", indent_level)

                      -- Apply indentation to non-empty lines
                      if trimmed ~= "" then
                        table.insert(new_lines, current_indent .. trimmed)
                      else
                        -- Preserve empty lines as-is
                        table.insert(new_lines, "")
                      end
                    end
                  end

                  -- Apply the changes to the buffer
                  vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)
                end

                indent_namespaces()
                vim.notify("Indented namespace blocks", vim.log.levels.INFO)
              end,
            })
          end,
        },
      },
    },
  },
}
