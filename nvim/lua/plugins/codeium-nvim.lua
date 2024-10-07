return {
  "Exafunction/codeium.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "hrsh7th/nvim-cmp",
  },
  config = function()
      require("codeium").setup({
        tools = {
          -- language_server = "${packages.codeium-lsp}/bin/codeium-lsp"
          -- language_server = "codeium_language_server"
          language_server = "/nix/store/k8db186m3xyvgz143rw5pzjphinkwakz-codeium-1.20.9/bin/codeium_language_server"
        };
      })
  end
}
