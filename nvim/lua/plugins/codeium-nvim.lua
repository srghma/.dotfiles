return {
  -- { import = "astrocommunity.completion.codeium-vim" },

  -- { import = "astrocommunity.completion.codeium-nvim" },

  {
    "dimfeld/codeium.nvim",
    -- branch = "fix-chat",
    commit = "a6e2df0bb14ed9089d79cc59619b5723ac1e5e47",
    -- "Exafunction/codeium.nvim",
    event = "User AstroFile",
    cmd = "Codeium",
    opts = {
      enable_chat = true,
      -- wrapper = "wrap-codeium-nix-alien",
      wrapper = "/home/srghma/.dotfiles/bin/wrap-codeium-nix-alien",
    },
    dependencies = {
      {
        "AstroNvim/astroui",
        ---@type AstroUIOpts
        opts = {
          icons = {
            Codeium = "",
          },
        },
      },
      {
        "AstroNvim/astrocore",
        ---@param opts AstroCoreOpts
        opts = function(_, opts)
          return require("astrocore").extend_tbl(opts, {
            mappings = {
              n = {
                ["<Leader>;"] = {
                  desc = require("astroui").get_icon("Codeium", 1, true) .. "Codeium",
                },
                ["<Leader>;o"] = {
                  desc = "Open Chat",
                  function() vim.cmd "Codeium Chat" end,
                },
              },
            },
          })
        end,
      },
    },
    specs = {
      {
        "hrsh7th/nvim-cmp",
        optional = true,
        opts = function(_, opts)
          -- Inject codeium into cmp sources, with high priority
          table.insert(opts.sources, 1, {
            name = "codeium",
            group_index = 1,
            priority = 10000,
          })
        end,
      },
      {
        "onsails/lspkind.nvim",
        optional = true,
        -- Adds icon for codeium using lspkind
        opts = function(_, opts)
          if not opts.symbol_map then opts.symbol_map = {} end
          opts.symbol_map.Codeium = require("astroui").get_icon("Codeium", 1, true)
        end,
      },
    },
  },

  -- {
  --   "Exafunction/codeium.nvim",
  --   cmd = { "Codeium" },
  --   opts = {
  --     -- tools = {
  --     --   uname = "/nix/store/3rkmqbpa9x1cq16i7yz1rjl02z6i6p61-coreutils-full-9.5/bin/coreutils",
  --     --   uuidgen = "/nix/store/f3mrhapkqr1lds8x58fh6rwm1lwh8y8c-util-linux-2.39.4-bin/bin/uuidgen",
  --     --   gzip = "/nix/store/164s7a7yscnicprzrr78bvk45d77a3yg-gzip-1.13/bin/gzip",
  --     --   curl = "/nix/store/6r0bn0dkvlvhicyvair205s07m92dpaz-curl-8.9.1-bin/bin/curl",
  --     --   language_server = "/nix/store/k8db186m3xyvgz143rw5pzjphinkwakz-codeium-1.20.9/bin/codeium_language_server",
  --     -- },
  --     -- enable_local_search = true,
  --     -- enable_index_service = true,
  --     -- wrapper = "steam-run",
  --     -- chmod +x ./bin/wrap-codeium-nix-alien
  --     wrapper = "wrap-codeium-nix-alien",
  --   },
  -- },

  -- {
  --   "Exafunction/codeium.nvim",
  --   opts = {
  --     tools = {
  --       language_server = "/nix/store/k8db186m3xyvgz143rw5pzjphinkwakz-codeium-1.20.9/bin/codeium_language_server",
  --     },
  --   },
  -- },
}

-- return {
--   "Exafunction/codeium.nvim",
--   -- config = function()
--   --     require("codeium").setup({
--   --       tools = {
--   --         -- language_server = "${packages.codeium-lsp}/bin/codeium-lsp"
--   --         -- language_server = "codeium_language_server"
--   --         language_server = "/nix/store/k8db186m3xyvgz143rw5pzjphinkwakz-codeium-1.20.9/bin/codeium_language_server"
--   --       };
--   --     })
--   -- end
--   opts = {
--     tools = {
--       language_server = "/nix/store/k8db186m3xyvgz143rw5pzjphinkwakz-codeium-1.20.9/bin/codeium_language_server"
--     }
--   }
-- }
