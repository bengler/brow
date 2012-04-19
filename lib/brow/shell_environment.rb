# A place for shell hacks

module Brow::ShellEnvironment

  # Execute a command in an environment that strive to 
  # support bundler, rbenv and perhaps even rvm
  def self.exec(commands, dir = ENV['HOME'])
    if File.exist?(File.join(ENV['HOME'], '.rbenv'))
      dir = "#{dir}/" unless dir =~ /\/$/
      ENV['RBENV_DIR'] = dir 
    end
    cmdline = "cd #{dir}"
    if File.exist?(File.join(dir, '.rvmrc'))
      # For RVM, we must make sure we trust our .rvmrc, which also requires
      # reloading RVM
      cmdline << ' && rvm rvmrc trust'
      cmdline << ' && rvm reload'
    end
    cmdline << ' && ('
    cmdline << commands.gsub(%("), %(\\"))
    cmdline << ')'
    `bash -lc "#{cmdline}"`
  end

end