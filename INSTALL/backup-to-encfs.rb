#! /usr/bin/env nix-shell
#! nix-shell -i ruby -p ruby

require 'fileutils'

encfs = "/home/srghma/Encfs/Private"

# /home/srghma/.config/google-chrome-beta
files = %w(
  /home/srghma/.config/google-chrome
  /home/srghma/.config/google-chrome-beta-for-srghma-chinese
  /home/srghma/projects/nuuz
  /home/srghma/projects/vd-rails
  /home/srghma/projects/zsh-nordicres
  /home/srghma/.ssh
  /home/srghma/.aws
  /home/srghma/.docker
  /home/srghma/.gdfuse
)

files.each do |source_dir|
  basename = File.basename(source_dir)
  target_path = File.join(encfs, basename)
  FileUtils.mv(source_dir, target_path)
  # FileUtils.ln_s(target_path, source_dir)
end
