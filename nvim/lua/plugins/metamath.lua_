return {
  dir = "/home/srghma/projects/metamath-vim",
  -- dir = "/home/srghma/.local/share/nvim/lazy/vim-metamath/vim"
  -- "david-a-wheeler/vim-metamath",
  -- dir = "vim",
  config = function()
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "metamath",
      callback = function()
        -- Set commentstring to "$( %s $)"
        -- Important: The spaces inside are required for Metamath syntax
        vim.bo.commentstring = "$( %s $)"
      end,
    })
  end,
}
