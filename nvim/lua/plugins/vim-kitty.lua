return {
  'knubie/vim-kitty-navigator',
  build = 'sh -c "[ -d "~/.config/kitty/" ] && cp ./*.py ~/.config/kitty/"',
  init = function()
    vim.api.nvim_create_autocmd({ 'VimEnter', 'VimResume' }, {
      group = vim.api.nvim_create_augroup('KittySetVarVimEnter', { clear = true }),
      callback = function()
        io.stdout:write '\x1b]1337;SetUserVar=in_vim=MQo\007'
      end,
    })

    vim.api.nvim_create_autocmd({ 'VimLeave', 'VimSuspend' }, {
      group = vim.api.nvim_create_augroup('KittyUnsetVarVimLeave', { clear = true }),
      callback = function()
        io.stdout:write '\x1b]1337;SetUserVar=in_vim\007'
      end,
    })
  end,
}
