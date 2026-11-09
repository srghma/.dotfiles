-- Read the docs: https://www.lunarvim.org/docs/configuration
-- Example configs: https://github.com/LunarVim/starter.lvim
-- Video Tutorials: https://www.youtube.com/watch?v=sFA9kX-Ud_c&list=PLhoH5vyxr6QqGu0i7tt_XoVK9v-KvZ3m6
-- Forum: https://www.reddit.com/r/lunarvim/
-- Discord: https://discord.com/invite/Xb9B4Ny

lvim.builtin.alpha.active = false
lvim.builtin.dap.active = false -- debug adapter
vim.opt.clipboard = "unnamed" -- on `d` - dont put deleted text to clipboard

-- Autosession
vim.opt.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
vim.opt.relativenumber = true -- relative line numbers
vim.opt.wrap = true -- wrap lines
-- lvim.builtin.indentlines.active = false

-- vim.opt.iskeyword:remove("_")
vim.opt.iskeyword = "@,48-57,192-255,_"

local function on_attach(bufnr)
  local api = require "nvim-tree.api"
  local function telescope_find_files(_)
    require("lvim.core.nvimtree").start_telescope "find_files"
  end
  local function telescope_live_grep(_)
    require("lvim.core.nvimtree").start_telescope "live_grep"
  end
  local function opts(desc)
    return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end
  api.config.mappings.default_on_attach(bufnr)
  local useful_keys = {
    ["i"] = { api.node.open.edit, opts "Open" },
    ["l"] = { api.node.open.edit, opts "Open" },
    ["o"] = { api.node.open.edit, opts "Open" },
    ["<CR>"] = { api.node.open.edit, opts "Open" },
    ["v"] = { api.node.open.vertical, opts "Open: Vertical Split" },
    ["I"] = { api.node.open.horizontal, opts "Open: Horizontal Split" },
    ["x"] = { api.node.navigate.parent_close, opts "Close Directory" },
    ["C"] = { api.tree.change_root_to_node, opts "CD" },
    ["gtg"] = { telescope_live_grep, opts "Telescope Live Grep" },
    ["gtf"] = { telescope_find_files, opts "Telescope Find File" },
  }
  require("lvim.keymappings").load_mode("n", useful_keys)
end
lvim.builtin.nvimtree.setup.on_attach = on_attach
lvim.builtin.nvimtree.setup.update_cwd = false
lvim.builtin.nvimtree.setup.disable_netrw = true
lvim.builtin.nvimtree.setup.update_focused_file.update_root = false

-----------------------------------------------------------

-- WAIT
-- local highlight = {
--     "RainbowRed",
--     "RainbowYellow",
--     "RainbowBlue",
--     "RainbowOrange",
--     "RainbowGreen",
--     "RainbowViolet",
--     "RainbowCyan",
-- }
-- -- Remove hooks usage since it causes issues
-- vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
-- vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
-- vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
-- vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
-- vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
-- vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
-- vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })

-- lvim.builtin.indentlines.options.indent = {}
-- lvim.builtin.indentlines.options.indent.highlight = highlight

-- lvim.builtin.indentlines.on_config_done = function()
--   local highlight = {
--       "RainbowRed",
--       "RainbowYellow",
--       "RainbowBlue",
--       "RainbowOrange",
--       "RainbowGreen",
--       "RainbowViolet",
--       "RainbowCyan",
--   }
--   local hooks = require "indent-blankline.hooks"
--   -- create the highlight groups in the highlight setup hook, so they are reset
--   -- every time the colorscheme changes
--   hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
--       vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
--       vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
--       vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
--       vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
--       vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
--       vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
--       vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
--   end)
--   lvim.builtin.indentlines.options.indent.highlight = highlight
-- end

-- lvim.builtin.indentlines.options.show_trailing_blankline_indent = false
-- lvim.builtin.indentlines.on_config_done = function()
--   vim.cmd([[highlight IndentBlanklineIndent1 guibg=#24283b gui=nocombine]])
--   vim.cmd([[highlight IndentBlanklineIndent2 guibg=#1f2335 gui=nocombine]])
-- end

-----------------------------------------------------------

lvim.builtin.treesitter.rainbow.enable = true


lvim.plugins = {
  { "tpope/vim-repeat" },
  { "tpope/vim-surround" },
  { "mhinz/vim-sayonara" },

  {
    "monaqa/dial.nvim",
    event = "BufRead",
    config = function()
      vim.keymap.set("n", "<C-s>", function()
          require("dial.map").manipulate("increment", "normal")
      end)
      vim.keymap.set("n", "<C-x>", function()
          require("dial.map").manipulate("decrement", "normal")
      end)
      vim.keymap.set("n", "g<C-s>", function()
          require("dial.map").manipulate("increment", "gnormal")
      end)
      vim.keymap.set("n", "g<C-x>", function()
          require("dial.map").manipulate("decrement", "gnormal")
      end)
      vim.keymap.set("v", "<C-s>", function()
          require("dial.map").manipulate("increment", "visual")
      end)
      vim.keymap.set("v", "<C-x>", function()
          require("dial.map").manipulate("decrement", "visual")
      end)
      vim.keymap.set("v", "g<C-s>", function()
          require("dial.map").manipulate("increment", "gvisual")
      end)
      vim.keymap.set("v", "g<C-x>", function()
          require("dial.map").manipulate("decrement", "gvisual")
      end)

      local augend = require("dial.augend")
      require("dial.config").augends:register_group{
        -- default augends used when no group name is specified
        default = {
          augend.integer.alias.decimal,   -- nonnegative decimal number (0, 1, 2, 3, ...)
          augend.integer.alias.hex,       -- nonnegative hex number  (0x01, 0x1a1f, etc.)
          augend.date.alias["%Y/%m/%d"],  -- date (2022/02/19, etc.)
          augend.constant.new{
            elements = {"and", "or"},
            word = true, -- if false, "sand" is incremented into "sor", "doctor" into "doctand", etc.
            cyclic = true,  -- "or" is incremented into "and".
          },
          augend.constant.new{ elements = {"true", "false"}, word = true, cyclic = true },
          augend.constant.new{ elements = {"True", "False"}, word = true, cyclic = true },
          augend.constant.new{ elements = {"&&", "||"}, word = false, cyclic = true },
        },
      }
    end,
  },

  {
    "folke/todo-comments.nvim",
    event = "BufRead",
    config = function()
      require("todo-comments").setup()
    end,
  },

  {
    "itchyny/vim-cursorword",
      event = {"BufEnter", "BufNewFile"},
      config = function()
        vim.api.nvim_command("augroup user_plugin_cursorword")
        vim.api.nvim_command("autocmd!")
        vim.api.nvim_command("autocmd FileType NvimTree,lspsagafinder,dashboard,vista let b:cursorword = 0")
        vim.api.nvim_command("autocmd WinEnter * if &diff || &pvw | let b:cursorword = 0 | endif")
        vim.api.nvim_command("autocmd InsertEnter * let b:cursorword = 0")
        vim.api.nvim_command("autocmd InsertLeave * let b:cursorword = 1")
        vim.api.nvim_command("augroup END")
        end
  },

  --------------------------------
  -- => Textobj (https://github.com/chrisgrieser/nvim-various-textobjs?tab=readme-ov-file)
  --------------------------------
  { "kana/vim-textobj-user" },
  { "kana/vim-textobj-indent", dependencies = { "kana/vim-textobj-user" } },
  { "kana/vim-textobj-entire", dependencies = { "kana/vim-textobj-user" } },
  { "lucapette/vim-textobj-underscore", dependencies = { "kana/vim-textobj-user" } },
  { "beloglazov/vim-textobj-quotes", dependencies = { "kana/vim-textobj-user" } },
  { "kana/vim-textobj-line", dependencies = { "kana/vim-textobj-user" } },
  { "jasonlong/vim-textobj-css", dependencies = { "kana/vim-textobj-user" } },
  { "b4winckler/vim-angry", dependencies = { "kana/vim-textobj-user" } },
  { "saihoooooooo/vim-textobj-space", dependencies = { "kana/vim-textobj-user" } },

  { "jeetsukumaran/vim-indentwise" },
  -------------------------------------------------
  {
    "ggandor/lightspeed.nvim",
    event = "BufRead",
  },
  {
    'wfxr/minimap.vim',
    -- build = "cargo install --locked code-minimap",
    -- cmd = {"Minimap", "MinimapClose", "MinimapToggle", "MinimapRefresh", "MinimapUpdateHighlight"},
    config = function ()
      vim.cmd ("let g:minimap_width = 10")
      vim.cmd ("let g:minimap_auto_start = 1")
      vim.cmd ("let g:minimap_auto_start_win_enter = 1")
    end,
  },
  "mrjones2014/nvim-ts-rainbow",

  -- Vim Sneak --https://github.com/ggandor/lightspeed.nvim
  -- {
  --   "justinmk/vim-sneak",
  --   config = function()
  --     -- vim.g.sneak#streak = 1
  --   end
  -- },

  -- Vim Exchange
  -- "tommcdo/vim-exchange",
  "gbprod/substitute.nvim",

  -- Easy Align
  { "junegunn/vim-easy-align" },

  -- CamelCase Motion
  -- { "bkad/CamelCaseMotion" },
  {
    "chrisgrieser/nvim-spider",
    keys = {
      { "e", "<cmd>lua require('spider').motion('e')<CR>", mode = { "n", "o", "x" } },
      { "w", "<cmd>lua require('spider').motion('w')<CR>", mode = { "n", "o", "x" } },
      { "b", "<cmd>lua require('spider').motion('b')<CR>", mode = { "n", "o", "x" } },
    },
  },
  -------------------------------------------------
  -- Automatically save on exit insert mode
  {
    "Pocco81/auto-save.nvim",
    config = function()
      require("auto-save").setup()
    end,
  },
  'christoomey/vim-tmux-navigator'
	-- Small automated session manager
	-- {
	-- 	"rmagatti/auto-session",
	-- 	dependencies = {
	-- 		"nvim-telescope/telescope.nvim", -- Only needed if you want to use session lens
	-- 	},
	-- 	lazy = false,
	-- 	config = function()
	-- 		require("auto-session").setup({
 --        auto_restore_last_session = true,
 --        suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
 --        cwd_change_handling = true,
 --        post_cwd_changed_cmds = {
 --          function()
 --            -- Refresh lualine so the new session name is displayed in the status bar
 --            require("lualine").refresh()
 --          end
 --        }
	-- 		})
	-- 	end,
	-- },
}

-- Move current line
lvim.keys.normal_mode["]e"] = ":m .+1<CR>=="
lvim.keys.normal_mode["[e"] = ":m .-2<CR>=="
lvim.keys.visual_mode["]e"] = ":m '>+1<CR>gv=gv"
lvim.keys.visual_mode["[e"] = ":m '<-2<CR>gv=gv"

-- lvim.keys.normal_mode["w"] = "<Plug>CamelCaseMotion_w"
-- lvim.keys.normal_mode["b"] = "<Plug>CamelCaseMotion_b"
-- lvim.keys.normal_mode["e"] = "<Plug>CamelCaseMotion_e"
-- lvim.keys.normal_mode["ge"] = "<Plug>CamelCaseMotion_ge"

-- Map EasyAlign in visual and normal modes
lvim.keys.visual_mode["ga"] = "<Plug>(EasyAlign)"
lvim.keys.normal_mode["ga"] = "<Plug>(EasyAlign)"

lvim.keys.normal_mode['Q'] = ':Sayonara<CR>'
lvim.keys.normal_mode['<M-q>'] = ':Sayonara!<CR>'
-- lvim.keys.normal_mode['Q'] = ':<Cmd>BufferKill<CR>'
lvim.keys.normal_mode[',q'] = ':xa<CR>'
lvim.keys.normal_mode[',z'] = ':qa!<CR>'
lvim.keys.normal_mode[',S'] = ':SessionSave<CR>'

-- -- https://github.com/nvim-tree/nvim-tree.lua/wiki/Recipes#workaround-when-using-rmagattiauto-session
-- -- There is currently an issue with restoring nvim-tree fully when using rmagatti/auto-session. Upon restoring the session, nvim-tree buffer will be empty, sometimes positioned in strange places with random dimensions. This issue only happens when saving session with nvim-tree open. To prevent this from happening you can use the following autocmd:
-- vim.api.nvim_create_autocmd({ 'BufEnter' }, {
--   pattern = 'NvimTree*',
--   callback = function()
--     local api = require('nvim-tree.api')
--     local view = require('nvim-tree.view')
--     if not view.is_visible() then
--       api.tree.open()
--     end
--   end,
-- })

-------------------------------------------------------------------------------
-- https://github.com/nvim-tree/nvim-tree.lua/wiki/Open-At-Startup
local function open_nvim_tree(data)
  -- buffer is a real file on the disk
  local real_file = vim.fn.filereadable(data.file) == 1
  -- buffer is a [No Name]
  local no_name = data.file == "" and vim.bo[data.buf].buftype == ""
  if not real_file and not no_name then
    return
  end
  -- open the tree, find the file but don't focus it
  require("nvim-tree.api").tree.toggle({ focus = false, find_file = true, })
end
vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })
-------------------------------------------------------------------------------

-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- let g:NERDTreeMapQuit='Q'
lvim.keys.normal_mode["<F2>"] = "<cmd>NvimTreeToggle<CR>"
lvim.keys.normal_mode["<F3>"] = "<cmd>NvimTreeFocus<CR>"

lvim.keys.normal_mode[",ga"] = ":silent !git add --all<CR>"

-- Meta (Alt) + 8 to search backward for the word under the cursor
lvim.keys.normal_mode["<M-8>"] = "#"

-- -- Save file using Leader key (Space by default) + w
-- lvim.keys.normal_mode["<leader>w"] = ":w<CR>"

-- -- Generate ctags for the entire project using Leader + tag
-- lvim.keys.normal_mode["<leader>tag"] = ":!ctags -R .<CR>"

-- -- Toggle 'paste' mode with F6
-- lvim.keys.normal_mode["<F6>"] = ":set invpaste<CR>:set paste?<CR>"

-- -- Remap arrow keys for buffer and tab navigation
-- lvim.keys.normal_mode["<left>"] = ":bprev<CR>"
-- lvim.keys.normal_mode["<right>"] = ":bnext<CR>"
-- lvim.keys.normal_mode["<up>"] = ":tabnext<CR>"
-- lvim.keys.normal_mode["<down>"] = ":tabprev<CR>"

lvim.keys.normal_mode["#"] = "<Plug>(comment_toggle_linewise_current)"
lvim.keys.visual_mode["#"] = "<Plug>(comment_toggle_linewise_visual)"

-- -- Unimpaired style mappings for tab navigation
lvim.keys.normal_mode["]t"] = ":tabnext<CR>"
lvim.keys.normal_mode["[t"] = ":tabprev<CR>"
lvim.keys.normal_mode["]b"] = "<cmd>BufferLineCycleNext<CR>"
lvim.keys.normal_mode["[b"] = "<cmd>BufferLineCyclePrev<CR>"

-- Insert newline after the current line
lvim.keys.normal_mode["]<space>"] = ":normal! o<ESC>cc<ESC>k"
lvim.keys.normal_mode["[<space>"] = ":normal! O<ESC>cc<ESC>j"

-- -- Quick resizing of splits using Meta (Alt) + h, l, j, k
lvim.keys.normal_mode["<M-h>"] = "<C-w>3<"
lvim.keys.normal_mode["<M-l>"] = "<C-w>3>"
lvim.keys.normal_mode["<M-j>"] = "<C-w>3-"
lvim.keys.normal_mode["<M-k>"] = "<C-w>3+"

-- -- Remap movement keys in command-line mode (cnoremap)
-- vim.api.nvim_set_keymap('c', '<M-h>', '<left>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('c', '<M-l>', '<right>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('c', '<M-j>', '<down>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('c', '<M-k>', '<up>', { noremap = true, silent = true })

-- -- Vim splits navigation (overwritten if tmux is active)
-- lvim.keys.normal_mode["<C-h>"] = "<C-w>h"
-- lvim.keys.normal_mode["<C-j>"] = "<C-w>j"
-- lvim.keys.normal_mode["<C-k>"] = "<C-w>k"
-- lvim.keys.normal_mode["<C-l>"] = "<C-w>l"

-- -- Kakoune-like movements
lvim.keys.normal_mode["gh"] = "0";  lvim.keys.visual_mode["gh"] = lvim.keys.normal_mode["gh"]
lvim.keys.normal_mode["gi"] = "^";  lvim.keys.visual_mode["gi"] = lvim.keys.normal_mode["gi"]
lvim.keys.normal_mode["gl"] = "g_"; lvim.keys.visual_mode["gl"] = lvim.keys.normal_mode["gl"]
lvim.keys.normal_mode["gj"] = "G";  lvim.keys.visual_mode["gj"] = lvim.keys.normal_mode["gj"]
lvim.keys.normal_mode["gk"] = "gg"; lvim.keys.visual_mode["gk"] = lvim.keys.normal_mode["gk"]

-- -- Insert mode remaps for register insertions
lvim.keys.insert_mode["<C-r>"] = "<C-r><C-p>"
lvim.keys.insert_mode["<M-p>"] = "<C-r><C-p>+"
lvim.keys.command_mode["<M-p>"] = "<C-r>+"

-- -- Paste from system clipboard
lvim.keys.normal_mode["p"] = '"+p'; lvim.keys.visual_mode["p"] = lvim.keys.normal_mode["p"]
lvim.keys.normal_mode["P"] = '"+P'; lvim.keys.visual_mode["P"] = lvim.keys.normal_mode["P"]

-- -- Copy from system clipboard
lvim.keys.normal_mode["y"] = '"+y'; lvim.keys.visual_mode["y"] = lvim.keys.normal_mode["y"]
lvim.keys.normal_mode["Y"] = '"+y$'

-- -- Delete and yank mappings
lvim.keys.normal_mode[",d"] = '"+d'; lvim.keys.visual_mode[",d"] = lvim.keys.normal_mode[",d"]
lvim.keys.normal_mode[",D"] = '"+D'; lvim.keys.visual_mode[",D"] = lvim.keys.normal_mode[",D"]

lvim.keys.normal_mode[",w"] = ':w!<CR>'; lvim.keys.visual_mode[",w"] = lvim.keys.normal_mode[",w"]

lvim.keys.normal_mode["<backspace>"] = '<Cmd>nohlsearch<CR>'

-- -- Deleting in insert mode
-- vim.api.nvim_set_keymap('i', '<C-u>', '<C-g>u<C-u>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('i', '<C-d>', '<Del>', { noremap = true, silent = true })

-- -- Sane regex search
-- lvim.keys.normal_mode["/"] = "/\\v"
-- lvim.keys.normal_mode["?"] = "?\\v"

-- -- Quick substitute commands
-- Define Lua functions to handle substitutions
lvim.keys.normal_mode['dm'] = ':lua vim.api.nvim_input(\':%s//<Right><Right><Right><Right>\')<CR>'
lvim.keys.visual_mode['dm'] = ':lua vim.api.nvim_input(\':s//<Right><Right><Right>\')<CR>'

-- lvim.keys.normal_mode["dm"] = ":%s:::g<left><left><left>"
-- lvim.keys.visual_mode["dm"] = ":s:::g<left><left><left>"

-- -- Fold commands with echoing fold level
-- lvim.keys.normal_mode["zr"] = "zr:echo &foldlevel<CR>"
-- lvim.keys.normal_mode["zm"] = "zm:echo &foldlevel<CR>"
-- lvim.keys.normal_mode["zR"] = "zR:echo &foldlevel<CR>"
-- lvim.keys.normal_mode["zM"] = "zM:echo &foldlevel<CR>"

-- -- Screen line scrolling (line wrapping aware)
-- vim.api.nvim_set_keymap('n', 'j', 'v:count > 1 ? "j" : "gj"', { expr = true, noremap = true })
-- vim.api.nvim_set_keymap('n', 'k', 'v:count > 1 ? "k" : "gk"', { expr = true, noremap = true })

-- -- Auto-center jumps
-- lvim.keys.normal_mode["<C-o>"] = "<C-o>zz"
-- lvim.keys.normal_mode["<C-i>"] = "<C-i>zz"

-- -- Reselect visual block after indent
lvim.keys.visual_mode["<"] = '<gv'
lvim.keys.visual_mode[">"] = '>gv'

-- -- Reselect last paste
-- vim.api.nvim_set_keymap('n', 'gp', '`['..strpart(getregtype(), 0, 1)..'`]', { expr = true, noremap = true })

-- -- Window management
lvim.keys.normal_mode[",v"] = "<C-w>v<C-w>l"
lvim.keys.normal_mode[",s"] = "<C-w>s"
lvim.keys.normal_mode[",vsa"] = ":vert sba<CR>"

-- -- Tab management
-- lvim.keys.normal_mode["<leader>tn"] = ":tab spl<CR>"
-- lvim.keys.normal_mode["<leader>tc"] = ":tabclose<CR>"

-- -- Quick buffer open
-- lvim.keys.normal_mode["gb"] = ":ls<CR>:e #"

-- -- General shortcuts
-- lvim.keys.normal_mode["<leader>l"] = ":set list! list?<CR>"
-- lvim.keys.normal_mode["<BS>"] = ":noh<CR>"
-- lvim.keys.normal_mode["<M-v>"] = "vg_"

-- -- Increment numbers
-- lvim.keys.normal_mode["<C-s>"] = "<C-a>"

-- -- Reload config
-- lvim.keys.normal_mode["<leader>R"] = ":so $MYVIMRC<CR>"

-- -- Terminal mode mappings
-- vim.api.nvim_set_keymap('t', '<C-\\><C-\\>', '<C-\\><C-n>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('t', '<left>', '<C-\\><C-n>:bprev<CR>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('t', '<right>', '<C-\\><C-n>:bnext<CR>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('t', '<up>', '<C-\\><C-n>:tabnext

-- DUPLICATE LINES

-- Define a Lua function to preserve cursor position and execute a command
function _G.preserve(command)
  -- Save the current cursor position and search pattern
  local pos = vim.api.nvim_win_get_cursor(0)
  local search = vim.fn.getreg('/')

  -- Execute the given command
  vim.cmd(command)

  -- Restore the previous cursor position and search pattern
  vim.fn.setreg('/', search)
  vim.api.nvim_win_set_cursor(0, pos)
end

-- Map Ctrl+Alt+d to duplicate the current line in normal mode
lvim.keys.normal_mode["<C-M-d>"] = ':lua _G.preserve("normal! yyp")<CR>'
lvim.keys.visual_mode["<C-M-d>"] = ':copy \'><CR>'

-- Key mapping for Indentation Wise Navigation
-- Adjust these mappings to your preferred plugin or function

lvim.lsp.buffer_mappings.normal_mode = {
  ["gK"] = { "<cmd>lua vim.lsp.buf.hover()<CR>", "Show hover" },
  ["gd"] = { "<cmd>lua vim.lsp.buf.definition()<CR>", "Goto Definition" },
  ["gD"] = { "<cmd>lua vim.lsp.buf.declaration()<CR>", "Goto declaration" },
  ["gr"] = { "<cmd>lua vim.lsp.buf.references()<CR>", "Goto references" },
  ["gI"] = { "<cmd>lua vim.lsp.buf.implementation()<CR>", "Goto Implementation" },
  ["gs"] = { "<cmd>lua vim.lsp.buf.signature_help()<CR>", "show signature help" },
  ["gp"] = { "<cmd>lua require'lvim.lsp.peek'.Peek('definition')<CR>", "Peek definition" },
  ["gL"] = { "<cmd>lua require'lvim.lsp.handlers'.show_line_diagnostics()<CR>", "Show line diagnostics" }
}

lvim.keys.normal_mode["K"] = "<Plug>(IndentWiseBlockScopeBoundaryBegin)"; lvim.keys.visual_mode["K"] = lvim.keys.normal_mode["K"]

-- Mapping J to navigate to the end of the block scope boundary
lvim.keys.normal_mode["J"] = "<Plug>(IndentWiseBlockScopeBoundaryEnd)"; lvim.keys.visual_mode["J"] = lvim.keys.normal_mode["J"]

-- Mapping Alt-i to J (already mapped above)
lvim.keys.normal_mode["<M-i>"] = "J"
