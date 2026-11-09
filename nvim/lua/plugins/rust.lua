return {
  { import = "astrocommunity.pack.rust" },

  -- The community pack uses `rustaceanvim`, which automatically merges settings
  -- from the `astrolsp` configuration for `rust_analyzer`.
  -- So, we just need to provide the settings in the correct `astrolsp` block.
  -- This ensures our settings are picked up by rustaceanvim's setup logic.
  {
    "AstroNvim/astrolsp",
    ---@type AstroLSPOpts
    opts = {
      config = {
        rust_analyzer = {
          settings = {
            ["rust-analyzer"] = {
              -- SETTINGS TO REDUCE MEMORY USAGE
              check = {
                -- This is the most important setting to prevent OOM issues
                -- It stops rust-analyzer from checking the entire workspace on every change.
                -- command = "clippy",
                allTargets = false,
              },
              cargo = {
                allTargets = false,
              },

              -- Other useful settings
              procMacro = {
                enable = true, -- Or false if proc-macros are causing issues
              },
              files = {
                -- Exclude large directories from being watched
                exclude = {
                  ".direnv",
                  ".git",
                  "target",
                },
              },
              inlayHints = {
                enable = false,
              },
            },
          },
        },
      },
    },
  },
}
