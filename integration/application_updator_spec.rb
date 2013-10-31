require 'brow/shell_environment'
require 'brow/application'
require 'brow/application/updator'

def project_dir
  @project_dir ||= File.expand_path(File.dirname(__FILE__) + '/../')
end

def tmp_repo
  "/tmp/browapp"
end

def go_there_cmd
  "cd #{tmp_repo}"
end

def make_repo
  %x{mkdir #{tmp_repo}}
  copy_repo = "cp -r #{project_dir}/.git* ."
  %x{#{go_there_cmd} && #{copy_repo}}
end

def cleanup
  %x{rm -rf /tmp/browapp}
end

def reset
  %x{#{go_there_cmd} && git reset --hard c71f20b6 && git stash list || git stash drop}
end

def really_hard_reset
  cleanup && make_repo && reset
end

describe Brow::Application::Updator do

  before(:all) { really_hard_reset }

  after(:each) { reset }
  let(:app) { Brow::Application.new(tmp_repo) }
  subject { Brow::Application::Updator.new(app) }

  context "when clean" do
    its(:dirty?) { should be_false }
  end

  context "when dirty" do
    before(:each) { %x{#{go_there_cmd} && echo "hello world" >> brow.gemspec} }

    it(:dirty?) { should be_true }

    it "can stash properly" do
      message = subject.stash
      result = subject.exec("git stash list -1 | grep '#{message}'")
      result.should_not eq('')
    end
  end

  context "problems with pull" do
    before(:each) { really_hard_reset }

    it "handles untracked branches" do
      subject.exec('git checkout -q -b testing')
      subject.should be_untracked
    end

    it "handles conflicts" do
      checkout = "git reset --hard ce7c4ac"
      copy = "cp #{project_dir}/spec/fixtures/conflicted_gitignore.rb #{tmp_repo}/lib/brow/gitignore.rb"
      commit = "git commit -am 'introduce conflict'"
      subject.exec "#{checkout} && #{copy} && #{commit}"
      subject.should be_conflicted
    end
  end
end
