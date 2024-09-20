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

function focus_some_file(mylambda)
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

    opts.window.position = "left"
    opts.window.width = 40

    opts.window.mappings["K"] = "focus_first_file_in_directory"
    opts.window.mappings["J"] = "focus_last_file_in_directory"
    opts.window.mappings["<cr>"] = "open_with_window_picker"
    opts.window.mappings["o"] = "split_with_window_picker"
    opts.window.mappings["O"] = "vsplit_with_window_picker"
    opts.window.mappings["s"] = false
    opts.window.mappings["S"] = false
    opts.window.mappings["/"] = false
    opts.window.mappings["f/"] = "fuzzy_finder"

    -- don't steal from 'zz'
    opts.window.mappings["z"] = false
    opts.window.mappings["Z"] = "close_all_nodes"
    opts.window.mappings["zz"] = function(state) vim.cmd("normal! zz") end

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
