-- AstroCore provides a central place to modify mappings, vim options, autocommands, and more!
-- Configuration documentation can be found with `:h astrocore`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    -- vim options can be configured here
    options = {
      opt = { -- vim.opt.<key>
        relativenumber = true, -- sets vim.opt.relativenumber
        number = true, -- sets vim.opt.number
        spell = false, -- sets vim.opt.spell
        signcolumn = "yes", -- sets vim.opt.signcolumn to yes
        wrap = true, -- sets vim.opt.wrap
        clipboard = "unnamed",
      },
      g = { -- vim.g.<key>
        -- codeium_bin = "/nix/store/k8db186m3xyvgz143rw5pzjphinkwakz-codeium-1.20.9/bin/codeium_language_server",
        -- configure global vim variables (vim.g)
        -- NOTE: `mapleader` and `maplocalleader` must be set in the AstroNvim opts or before `lazy.setup`
        -- This can be found in the `lua/lazy_setup.lua` file
      },
    },
    ------------------------------------------------------------------------------
    -- Configuration table of session options for AstroNvim's session management powered by Resession
    sessions = {
      -- Configure auto saving
      autosave = {
        last = true, -- auto save last session
        cwd = true, -- auto save session for each working directory
      },
      -- Patterns to ignore when saving sessions
      ignore = {
        dirs = {}, -- working directories to ignore sessions in
        filetypes = { "gitcommit", "gitrebase" }, -- filetypes to ignore sessions
        buftypes = {}, -- buffer types to ignore sessions
      },
    },
    -----------------------------------
    autocmds = {
      -- disable alpha autostart
      alpha_autostart = false,
      restore_session = {
        {
          event = "VimEnter",
          desc = "Restore previous directory session if neovim opened with no arguments",
          nested = true, -- trigger other autocommands as buffers open
          callback = function()
            -- Only load the session if nvim was started with no args
            if vim.fn.argc(-1) == 0 then
              -- try to load a directory session using the current working directory
              require("resession").load(vim.fn.getcwd(), { dir = "dirsession", silence_errors = true })
            end
          end,
        },
      },
      set_lean_commentstring = {
        {
          event = "FileType",
          pattern = "lean",
          callback = function()
            vim.bo.commentstring = "-- %s"
            vim.bo.comments = ":--"
          end,
        },
      },
      remove_lean_comments_cmd = {
        {
          event = "FileType",
          pattern = "lean",
          callback = function()
            local function register_buffer_command_and_keymap(opts)
              vim.keymap.set("n", opts.keymap, opts.fn, {
                buffer = bufnr,
                desc = opts.desc,
              })

              vim.api.nvim_buf_create_user_command(0, opts.command, opts.fn, {
                desc = opts.desc,
              })
            end


            register_buffer_command_and_keymap({
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

            register_buffer_command_and_keymap({
              keymap = "<leader>lK",
              command = "KeepLeanDefinitions",
              desc = "Keep only Lean definitions (def, instance, class, etc.)",
              fn = function()
                vim.cmd [[silent! g!/^.*\<\(def\|instance\|class\|abbrev\|opaque\|extern\|section\|end\|namespace\|inductive\)\>/d]]
                vim.cmd('silent! g/^@\\[\\s\\+extern[^]]\\+\\]\\s*$/join')
                vim.notify("Kept only Lean definitions", vim.log.levels.INFO)
              end,
            })

            register_buffer_command_and_keymap({
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

                  for i, line in ipairs(lines) do
                    local trimmed = line:match("^%s*(.-)%s*$")

                    -- Check if line starts a namespace
                    if trimmed:match("^namespace%s+") then
                      -- Keep namespace line with current indentation level
                      local current_indent = string.rep("  ", indent_level)
                      table.insert(new_lines, current_indent .. trimmed)
                      -- Increase indent level for content inside this namespace
                      indent_level = indent_level + 1

                    -- Check if line is an end statement (matching namespace or other blocks)
                    elseif trimmed:match("^end%s") or trimmed == "end" then
                      -- Decrease indent level first
                      if indent_level > 0 then
                        indent_level = indent_level - 1
                      end
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

    -- Configure core features of AstroNvim
    features = {
      large_buf = { size = 1024 * 256, lines = 10000 }, -- set global limits for large files for disabling features like treesitter
      autopairs = true, -- enable autopairs at start
      cmp = true, -- enable completion at start
      diagnostics = { virtual_text = true, virtual_lines = false }, -- diagnostic settings on startup
      highlighturl = true, -- highlight URLs at start
      notifications = true, -- enable notifications at start
    },
    -- Diagnostics configuration (for vim.diagnostics.config({...})) when diagnostics are on
    diagnostics = {
      virtual_text = true,
      underline = true,
    },
    -- Mappings can be configured through AstroCore as well.
    -- NOTE: keycodes follow the casing in the vimdocs. For example, `<Leader>` must be capitalized
    mappings = {
      o = {
        -- Kakoune-like movements
        ["gh"] = "0",
        ["gi"] = "^",
        ["gl"] = "g_",
        ["gj"] = "G",
        ["gk"] = "gg",
      },
      i = {
        -- Insert mode remaps for register insertions
        ["<C-r>"] = "<C-r><C-p>",
        ["<M-p>"] = "<C-r><C-p>+",
      },
      c = {
        ["<M-p>"] = "<C-r>+",

        -- change cursor position in command mode
        ["<M-h>"] = "<left>",
        ["<M-l>"] = "<right>",
        ["<M-j>"] = "<down>",
        ["<M-k>"] = "<up>",
      },
      v = {
        -- Kakoune-like movements
        ["gh"] = "0",
        ["gi"] = "^",
        ["gl"] = "g_",
        ["gj"] = "G",
        ["gk"] = "gg",

        -- Reselect visual block after indent
        -- ["<"] = { '<gv' },
        -- [">"] = { '>gv' },

        -- ["]e"] = { ":m '>+1<CR>gv=gv" }, -- mini.move
        -- ["[e"] = { ":m '<-2<CR>gv=gv" },

        -- Use minioperators.multiply gmm
        ["<C-M-d>"] = ':lua require("mini.operators").multiply("visual")<CR>',

        -- Move current line
        ["]e"] = { ":m .+1<CR>==" },
        ["[e"] = { ":m .-2<CR>==" },
        -- Paste from system clipboard
        ["p"] = '"+p',
        ["P"] = '"+P',
        -- Copy from system clipboard
        ["y"] = '"+y',
        ["Y"] = '"+y$',
        -- Delete and yank mappings
        [",d"] = '"+d',
        [",D"] = '"+D',
        [",w"] = ":w!<CR>",

        ["#"] = { "gc", remap = true, desc = "Toggle comment" },

        ["."] = { ":normal .<CR>", desc = "Repeat last normal command" },

        ["dm"] = {
          [[:s///g<right><right>]],
          desc = "Replace inside of visual selection",
        },
        ["DM"] = {
          [[:Subs///g<Right><Right>]],
          desc = "Replace inside of visual selection",
        },
        -- ['dm'] = { [[:lua vim.api.nvim_input(":s//<Right><Right><Right>")<CR>]], desc = "Replace inside of visual selection" },
      },
      n = {
        -- Kakoune-like movements
        ["gh"] = "0",
        ["gi"] = "^",
        ["gl"] = "g_",
        ["gj"] = "G",
        ["gk"] = "gg",

        -- 🔍 literal grep (fixed string)
        -- ["<leader>f<C-W>"] = {
        --   function()
        --     Snacks.picker.grep({
        --       actions = {
        --         -- toggles arg --fixed-strings
        --         toggle_regex = function(picker, item)
        --           local opts = picker.opts --[[@as snacks.picker.grep.Config]]
        --           opts.regex = not opts.regex
        --           picker:find()
        --         end,
        --         glob_filter = function(picker, item)
        --           local opts = picker.opts --[[@as snacks.picker.grep.Config]]
        --           local prev_glob = opts.glob
        --           local glob = vim.fn.input("Enter glob filter: ", prev_glob or "")
        --           if prev_glob == glob then
        --             return
        --           end
        --           opts.custom_glob = #glob > 0
        --           opts.glob = glob
        --           picker:find()
        --         end,
        --         no_tests = function(picker, item)
        --           local glob = "{!**/tests/**,!**/*.spec.cy.tsx}"
        --           local prev_glob = picker.opts.glob
        --           if prev_glob == glob then
        --             picker.opts.glob = ""
        --           else
        --             picker.opts.glob = glob
        --           end
        --           picker:find()
        --         end,
        --       },
        --       win = {
        --         input = {
        --           keys = {
        --             ["r"] = { "toggle_regex", mode = { "n" } },
        --             ["g"] = { "glob_filter", mode = { "n" } },
        --             ["t"] = { "no_tests", mode = { "n" } },
        --           },
        --         },
        --       },
        --       regex = false,
        --       args = {
        --         "-g",
        --         "!{node_modules,.git,.direnv,dist}/",
        --         "-g",
        --         "!tsconfig.tsbuildinfo",
        --         "-g",
        --         "!yarn.lock",
        --         "--trim",
        --         "--ignore-case",
        --       },
        --       exclude = { "%.lock$", "%-lock.json$", "tsconfig.tsbuildinfo" },
        --     })
        --   end,
        --   desc = "Literal grep (fixed string)",
        -- },

        ["<C-M-d>"] = {
          function()
            local line = vim.fn.line "."
            local content = vim.fn.getline(line)
            vim.fn.setreg("a", content)
            vim.cmd "put a"
            vim.cmd "normal! k"
          end,
          desc = "Duplicate current line",
        },

        -- navigate buffer tabs
        ["]b"] = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" },
        ["[b"] = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" },

        ["<F2>"] = { "<Cmd>Neotree toggle<CR>" },
        ["<F3>"] = { "<Cmd>Neotree selector reveal<CR>" },

        [",ga"] = ":silent !git add --all<CR>:e!<CR>",

        -- Move current line
        -- ["]e"] = { ":m .+1<CR>==" },
        -- ["[e"] = { ":m .-2<CR>==" },

        ["dm"] = {
          ":lua vim.api.nvim_input(':%s::<Right><Right><Right><Right>')<CR>",
          desc = "Replace within all buffer",
        },
        ["DM"] = {
          ":lua vim.api.nvim_input(':Subs//<Right><Right><Right><Right>')<CR>",
          desc = "Replace within all buffer",
        },

        -- Paste from system clipboard
        ["p"] = '"+p',
        ["P"] = '"+P',
        -- Copy from system clipboard
        ["y"] = '"+y',
        ["Y"] = '"+y$',
        -- Delete and yank mappings
        [",d"] = '"+d',
        [",D"] = '"+D',
        [",w"] = ":w!<CR>",

        -- -- Window management
        [",v"] = { "<Cmd>vsplit<CR>", desc = "Vertical Split" },
        [",s"] = { "<Cmd>split<CR>", desc = "Horizontal Split" },
        -- [",v"] = "<C-w>v<C-w>l",
        -- [",s"] = "<C-w>s",
        -- [",vsa"] = ":vert sba<CR>",

        -- Insert newline after the current line
        ["]<space>"] = ":normal! o<ESC>cc<ESC>k",
        ["[<space>"] = ":normal! O<ESC>cc<ESC>j",

        ["<M-k>"] = { function() require("smart-splits").resize_up() end, desc = "Resize split up" },
        ["<M-j>"] = { function() require("smart-splits").resize_down() end, desc = "Resize split down" },
        ["<M-h>"] = { function() require("smart-splits").resize_left() end, desc = "Resize split left" },
        ["<M-l>"] = { function() require("smart-splits").resize_right() end, desc = "Resize split right" },

        -- mappings seen under group name "Buffer"
        ["<Leader>bd"] = {
          function()
            require("astroui.status.heirline").buffer_picker(
              function(bufnr) require("astrocore.buffer").close(bufnr) end
            )
          end,
          desc = "Close buffer from tabline",
        },

        ["<M-i>"] = "J", -- Mapping Alt-i to J (already mapped above)

        ["#"] = { "gcc", remap = true, desc = "Toggle comment line" },

        -- ["*"] = { "*#", remap = true, desc = "Search" },

        ["Q"] = { "<Cmd>confirm q<CR>", desc = "Quit Window" },
        ["<M-q>"] = { function() require("astrocore.buffer").close() end, desc = "Close buffer" },
        [",z"] = { "<Cmd>confirm qall<CR>", desc = "Exit AstroNvim" },

        [",q"] = { ":xa<CR>", desc = "Quit Window without save" },
        [",S"] = { function() require("resession").save() end, desc = "Save this session" },

        -- setting a mapping to false will disable it
        ["<C-s>"] = false,
        ["<C-S>"] = false,

        ["<leader>lc"] = {
          function()
            local line_num = vim.fn.line(".") - 1
            local diag = vim.diagnostic.get(0, { lnum = line_num })

            if diag and #diag > 0 then
              local msg = diag[1].message
              local line_content = vim.api.nvim_buf_get_lines(0, line_num, line_num + 1, false)[1] or ""
              local combined = "At: " .. line_content .. "\n  " .. msg
              vim.fn.setreg("+", combined)  -- copy to system clipboard
              vim.notify("Copied to clipboard:\n" .. combined, vim.log.levels.INFO)
            else
              vim.notify("No diagnostic on current line", vim.log.levels.WARN)
            end
          end,
          desc = "Copy diagnostic and line to clipboard",
        },

        ["<leader>oc"] = {
          function()
            local function get_copyq_content()
              local output = vim.fn.system({ "copyq", "read" }):gsub("\n$", "")
              return output ~= "" and output or nil
            end

            local function open_file_from_path(file_path)
              local expanded_path = vim.fn.fnamemodify(file_path, ":p")
              if vim.fn.filereadable(expanded_path) == 1 then
                vim.cmd("edit " .. vim.fn.fnameescape(expanded_path))
              else
                vim.notify("File not found: " .. file_path, vim.log.levels.ERROR)
              end
            end

            local file_path = get_copyq_content()
            if file_path then
              open_file_from_path(file_path)
            else
              vim.notify("No content found in CopyQ", vim.log.levels.WARN)
            end
          end,
          desc = "Open file path from CopyQ",
        },
      },
    },
  },
}
