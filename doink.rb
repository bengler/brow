dir = "/Users/simenss/.brow/pebbles/grove/"
ENV['RBENV_DIR'] = dir
system(<<-end)
  #eval "$(rbenv init -)"
  . $HOME/.bash_profile
  (cd #{dir}; ruby --version)
end
