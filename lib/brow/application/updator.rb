module Brow
  class Application
    class Updator

      attr_reader :application
      def initialize(application)
        @application = application
        @stashed = false
      end

      def root
        application.root
      end

      def exec(*commands)
        Brow::ShellEnvironment.run(commands.compact, root)
      end

      def update(&block)
        unless git?
          return "#{application.name} isn't a git repo."
        end

        if dirty?
          if block.call(stash_question)
            stash
          else
            return "Not stashing. Cannot continue."
          end
        end

        untracked? and return untracked_warning
        conflicted? and return conflicted_warning

        unless bundled?
          bundle_update
        end

        if migrations?
          migrate
        end

        if test_db?
          prepare_test_db
        end

        if stashed?
          if block.call(unstash_question)
            unstash
          end
        end
        return "Done."
      end

      def stash_question
        "The #{application.name} repo is dirty. Do you want to stash the changes? [yN]"
      end

      def unstash_question
        "Do you want to apply the stashed changes for #{application.name}? [yN]"
      end

      def git_status
        @git_status ||= exec("git status 2>&1")
      end

      def pull_rebase
        @pull_rebase ||= exec("git pull --rebase 2>&1")
      end

      def stashed?
        @stashed
      end

      def dirty?
        !git_status.scan('working directory clean').first
      end

      def git?
        !git_status.scan('Not a git repo').first
      end

      def conflicted?
        !!pull_rebase.scan('CONFLICT').first
      end

      def untracked?
        !!pull_rebase.scan('asked me to pull without telling me').first
      end

      def bundled?
        exec("bundle check") =~ /The Gemfile's dependencies are satisfied/
      end

      def migrations?
        tasks.any?{|task| task =~ /db:migrate/}
      end

      def test_db?
        tasks.any?{|task| task =~ /db:test:prepare/}
      end

      def tasks
        @tasks ||= exec("bundle exec rake -T  2>&1").split("\n")
      end

      def stash
        message = "Stashed by brow at #{Time.now}"
        exec("git stash save '#{message}'")
        @stashed = true
        message
      end

      def unstash
        exec('git stash pop 2>&1')
      end

      def bundle_update
        exec("bundle install 2>&1")
      end

      def migrate
        exec("bundle exec rake db:migrate 2>&1")
        exec("git checkout db/development_structure.sql")
      end

      def prepare_test_db
        exec("bundle exec rake db:test:prepare 2>&1")
      end

      def conflicted_warning
        pull_rebase
      end

      def untracked_warning
        branch = pull_rebase[/branch\.(\w+)\.merge/m, 1]
        warning = []
        warning << "You're not tracking #{branch} against any upstream branch."
        warning << ""
        warning << "This might come in handy:"
        warning << "git branch --set-upstream #{branch} origin/<upstreambranch>"
        warning.join("\n")
      end

    end
  end
end
