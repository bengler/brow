# A place for shell hacks
module Brow
  module ShellEnvironment

    # Execute a command in an environment that strive to
    # support bundler, rbenv and perhaps even rvm
    def self.build_command(commands, dir = ENV['HOME'])
      dir = "#{dir}/" unless dir =~ /\/$/

      cmdline = []
      if File.exist?(File.join(ENV['HOME'], '.rbenv')) and `which rbenv` != ''
        # Override RBENV_DIR and RBENV_VERSION
        cmdline.push "export RBENV_DIR=#{dir} RBENV_VERSION=''"
        %w(RBENV_VERSION RUBYOPT BUNDLE_GEMFILE BUNDLE_BIN_PATH GEM_HOME GEM_PATH).each do |key|
          cmdline.push "unset #{key}" if ENV[key]
        end
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

      %(bash -lc "#{cmdline.join(' && ')}")
    end

    def self.run(commands, dir = ENV['HOME'])
      system(build_command(commands, dir))
    end
  end
end
