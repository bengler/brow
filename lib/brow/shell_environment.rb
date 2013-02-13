# A place for shell hacks
module Brow
  module ShellEnvironment

    # Execute a command in an environment that strive to
    # support bundler, rbenv and perhaps even rvm
    def self.build_command(commands, dir = ENV['HOME'])
      if File.exist?(File.join(ENV['HOME'], '.rbenv'))
        dir = "#{dir}/" unless dir =~ /\/$/
          ENV['RBENV_DIR'] = dir
      end
      cmdline = []
      if File.exist?(File.join(ENV['HOME'], '.rbenv')) and `which rbenv` != ''
        # Override RBENV_DIR and RBENV_VERSION
        cmdline.push "export RBENV_DIR=#{dir} RBENV_VERSION=''"
        cmdline.push "cd '#{dir}'"
      elsif File.exist?(File.join(dir, '.rvmrc')) and `which rvm` != ''
        # For RVM, we must make sure we trust our .rvmrc, which also requires
        # reloading RVM
        cmdline.push "rvm rvmrc trust '#{dir}'"
        cmdline.push "cd '#{dir}'"
        cmdline.push "rvm reload"
      else
        cmdline.push "cd '#{dir}'"
      end
      gemfile = File.join(dir, 'Gemfile')
      if File.exists?(gemfile)
        cmdline.push "export BUNDLE_GEMFILE=#{gemfile}"
      end
      cmdline.push "export RUNNING_IN_BROW=1"
      cmdline.push "(#{commands.gsub(%("), %(\\"))})"

      %(env -i bash -lc "#{cmdline.join(' && ')}")
    end

    def self.exec(commands, dir = ENV['HOME'])
      `#{build_command(commands, dir)}`
    end
  end
end
