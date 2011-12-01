# A place for shell hacks

module Brow::ShellEnvironment

  # Execute a command in an environment that strive to 
  # support bundler, rbenv and perhaps even rvm
  def self.exec(commands, dir = ENV['HOME'])
    if File.exists?(ENV['HOME']+"/.rbenv")
      dir += '/' unless dir[-1] == '/'
      ENV['RBENV_DIR'] = dir 
    end
    ` . $HOME/.bash_profile
      cd #{dir} 
      #{commands}
    `
  end

end