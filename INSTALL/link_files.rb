#! /usr/bin/env nix-shell
#! nix-shell -i ruby -p ruby

require_relative './config'

inhome_indotfiles = [
  ['.zshrc',                                  'zshrc'],
  ['.tmux.conf',                              'tmux.conf'],
  ['.i3/config',                              'i3/config'],

  ['.config/ranger/commands.py',              'ranger/commands.py'],
  ['.config/ranger/rc.conf',                  'ranger/rc.conf'],
  ['.config/ranger/scope.sh',                 'ranger/scope.sh'],

  ['.stack/config.yaml',                      'stack-global.yaml'],
  ['.gitconfig',                              'gitconfig'],
  ['.gitignore_global',                       'gitignore_global'],
  ['.ctags',                                  'ctags'],
  ['.ncmpcpp/bindings',                       'ncmpcpp_bindings'],
  ['.config/kitty',                           'kitty'],
  ['.commitlintrc.yml',                       'commitlintrc.yml'],

  ['.local/share/applications/mimeapps.list', 'mimeapps.list'],
  ['.config/mimeapps.list',                   'mimeapps.list'],

  ['.config/Code/User/settings.json',         'Code/settings.json'],
  ['.config/Code/User/extensions.json',       'Code/extensions.json'],
  ['.config/Code/User/snippets',              'Code/snippets'],

  ['.Xresources',                             'Xresources'],
  ['.Xresources.d',                           'Xresources.d'],

  ['.config/nvim',                            'nvim'],

  ['.cabal/config',                           'cabal_config'],
  # ['.spaceemacs',                                          'spaceemacs'],
  ['.gnupg/gpg-agent.conf',                   'gpg-agent.conf'],
  ['.config/kak',                             'kak'],
  # ['.config/lvim/config.lua',               'lvim/config.lua'],

  # ['.emacs', 'emacs'],
]

inhome_indotfiles.each do |(inhome, indotfiles)|
  inhome_     = File.join $home, inhome
  indotfiles_ = File.join $dotfiles, indotfiles
  unless File.exist?(indotfiles_)
    puts "File doesnt exist #{indotfiles_}"
    next
  end
  `mkdir -p "$(dirname "#{inhome_}")"`
  `ln -sfT "#{indotfiles_}" "#{inhome_}"`
end
