local function log_to_file(content)
  local log_file = "/tmp/neo-tree-debug.log"
  local file = io.open(log_file, "a")  -- Open in append mode
  if file then
    file:write(content .. "\n")
    file:close()
  else
    print("Error opening log file!")
  end
end

local function focus_some_file(mylambda)
  return function(state)
    local log = require("neo-tree.log")

    -- Get the current node
    local tree = state.tree
    local success, node = pcall(tree.get_node, tree)
    -- log_to_file(vim.inspect(success))
    -- log_to_file(vim.inspect(node))

    if not (success and node) or node.type == "message" then
      log.debug("Could not get node.")
      return
    end

    -- Get the parent directory of the current node
    local directory = tree:get_node(node:get_parent_id())
    if not directory or directory.type ~= "directory" then
      log.debug("No parent directory found.")
      return
    end

    -- Get the children of the directory (files or subdirectories)
    local children = directory:get_child_ids()
    -- log_to_file(vim.inspect(children))
    if not children or #children == 0 then
      log.debug("No other files in directory.")
      return
    end

    -- Use the passed lambda function to determine which file to focus
    local target_child_id = mylambda(children)
    -- log_to_file(vim.inspect('target_child_id', target_child_id))

    if not target_child_id then
      log.debug("Could not get target node.")
      return
    end

    -- Focus the selected file
    local renderer = require("neo-tree.ui.renderer")
    renderer.focus_node(state, target_child_id, true)
  end
end

return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = function(_, opts)
    -- opts.filesystem.hijack_netrw_behavior = "open_default"
    opts.filesystem.filtered_items = opts.filesystem.filtered_items or {}
    opts.filesystem.filtered_items.visible = true
    opts.filesystem.filtered_items.hide_dotfiles = true
    opts.filesystem.filtered_items.hide_gitignored = true
    opts.filesystem.filtered_items.hide_by_name = { "node_modules", ".git" }
    opts.filesystem.filtered_items.never_show = { ".DS_Store", "thumbs.db", "desktop.ini" }

    opts.filesystem.follow_current_file.enabled = false -- This will find and focus the file in the active buffer every time
    opts.filesystem.follow_current_file.leave_dirs_open = true

    opts.commands["focus_first_file_in_directory"] = focus_some_file(function(x) return x[1] end)
    opts.commands["focus_last_file_in_directory"] = focus_some_file(function(x) return x[#x] end)

    local function print_inspect_to_file(data)
	    local filepath = "/tmp/mydebug.log"
	    local file = io.open(filepath, "a")
	    if not file then
		    vim.notify("Could not open file for writing: " .. filepath, vim.log.levels.ERROR)
		    return
	    end
	    file:write(vim.inspect(data) .. "\n")
	    file:close()
	    vim.notify(vim.inspect(data))
    end

    opts.window.mappings["@"] = "mycommand"
    opts.commands["mycommand"] = function(state)
	    if not state.clipboard then
		    vim.notify("No state.clipboard", vim.log.levels.ERROR)
		    return
	    end

      -- Get files marked for cut from the clipboard
      local marked_files = {}

      -- Check if clipboard stores nodes
      for _i, x in pairs(state.clipboard) do
        -- Check if the node is marked as cut (check for cut attribute)
        if x.action == "cut" and x.node.type == "file" then
          table.insert(marked_files, x.node.path)
        end
      end

      -- Ensure we have files in the clipboard
      if #marked_files == 0 then
        vim.notify("No files marked for cut. Mark files with 'x' first.", vim.log.levels.WARN)
        return
      end

      -- Check if register q has a macro
      local macro_content = vim.fn.getreg("q")
      vim.notify(macro_content)
      if not macro_content or macro_content == "" then
        vim.notify("No macro found in register 'q'. Record a macro with 'qq' first.", vim.log.levels.WARN)
        return
      end

      -- Store current node ID for restoring position
      -- local current_node = state.tree:get_node()
      -- local current_node_id = current_node and current_node:get_id()

      require("neo-tree.ui.renderer").close(state)

      -- Store current buffer and window
      local current_buf = vim.api.nvim_get_current_buf()
      local current_win = vim.api.nvim_get_current_win()

      -- Process cut files one by one
      -- local opened_files_count = 0
      --
      -- for _, item in ipairs(marked_files) do
      --   opened_files_count = opened_files_count + 1
      --   vim.cmd("edit " .. vim.fn.fnameescape(item))
      -- end
      --
      -- vim.notify("Files opened" .. opened_files_count .. " file(s)", vim.log.levels.INFO)

      -- Process cut files one by one
      local processed_count = 0

      for _, item in ipairs(marked_files) do
        processed_count = processed_count + 1

        -- Open file in a buffer
        vim.cmd("edit " .. vim.fn.fnameescape(item))

        -- Run the macro from register q
        vim.cmd("normal! @q")

        -- Save the file
        vim.cmd("write")
      end

      -- Return to the neo-tree window and buffer
      vim.api.nvim_set_current_win(current_win)
      vim.api.nvim_set_current_buf(current_buf)

      -- Try to restore the previous selection
      if current_node_id then
        require("neo-tree.ui.renderer").focus_node(state, current_node_id)
      end

      -- Show success message
      vim.notify("Ran macro '@q' on " .. processed_count .. " file(s)", vim.log.levels.INFO)
    end

    opts.window.position = "left"
    opts.window.width = 40

    -- opts.window.mappings["Q"] = {
    --   function(_state)
    --     local recording = vim.fn.reg_recording()
    --     if recording == "" then
    --       -- Start recording to register 'a'
    --       vim.api.nvim_feedkeys("qa", "n", false)
    --       vim.notify("Started recording macro to register 'a'")
    --     else
    --       -- Stop recording
    --       vim.api.nvim_feedkeys("q", "n", false)
    --       vim.notify("Stopped recording macro from register '" .. recording .. "'")
    --     end
    --   end,
    --   desc = "Toggle macro recording in register a",
    -- }
    --
    -- opts.window.mappings["@"] = {
    --   function(_state)
    --     vim.cmd("normal! @a")
    --   end,
    --   desc = "Run macro from register a",
    -- }

    opts.window.mappings["K"] = "focus_first_file_in_directory"
    opts.window.mappings["J"] = "focus_last_file_in_directory"
    opts.window.mappings["<cr>"] = "open_with_window_picker"
    opts.window.mappings["o"] = "split_with_window_picker"
    opts.window.mappings["O"] = "vsplit_with_window_picker"
    opts.window.mappings["s"] = false
    opts.window.mappings["S"] = false
    opts.window.mappings["/"] = false
    opts.window.mappings["f"] = false
    opts.window.mappings["ff"] = "filter_on_submit"
    opts.window.mappings["f/"] = "fuzzy_finder"

    -- don't steal from 'zz'
    opts.window.mappings["z"] = false
    opts.window.mappings["Z"] = "close_all_nodes"
    opts.window.mappings["zz"] = function(_state) vim.cmd("normal! zz") end

    opts.window.mappings["a"] = {
      "add",
      -- this command supports BASH style brace expansion ("x{a,b,c}" -> xa,xb,xc). see `:h neo-tree-file-actions` for details
      -- some commands may take optional config options, see `:h neo-tree-mappings` for details
      config = {
        show_path = "relative", -- "none", "relative", "absolute"
      },
    }

    -- opts.window.mappings["Yf"] = opts.window.mappings["Y"]
    -- opts.window.mappings["Y"] = nil
    -- opts.window.mappings["Yr"] = {
    --   function(state)
    --     local node = state.tree:get_node()
    --     local path = node:get_id()
    --     -- local root = require("lazyvim.util").root.get()
    --     local relative_path = vim.fn.fnamemodify(path, ":.")
    --     -- if vim.startswith(relative_path, root) then
    --     --   relative_path = vim.fn.fnamemodify(relative_path, ":s?" .. root .. "/??")
    --     -- end
    --     vim.fn.setreg("+", relative_path, "c")
    --   end,
    --   desc = "Copy Root relative path to Clipboard",
    -- }


    -- opts.source_selector.sources = {
    --   { source = "filesystem", display_name = "󰉓 Files" },
    -- }
  end,
}
