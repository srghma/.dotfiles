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
    },

    -- Configure core features of AstroNvim
    features = {
      large_buf = { size = 1024 * 256, lines = 10000 }, -- set global limits for large files for disabling features like treesitter
      autopairs = true, -- enable autopairs at start
      cmp = true, -- enable completion at start
      diagnostics_mode = 3, -- diagnostic mode on start (0 = off, 1 = no signs/virtual text, 2 = no virtual text, 3 = on)
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
          [[:s:::g<right><right>]],
          desc = "Replace inside of visual selection",
        },
        ["DM"] = {
          [[:Subs:::g<Right><Right>]],
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
          ":lua vim.api.nvim_input(':%Subs::<Right><Right><Right><Right>')<CR>",
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
      },
    },
  },
}
