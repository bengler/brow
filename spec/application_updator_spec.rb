require 'brow/application/updator'

describe Brow::Application::Updator do
  subject { Brow::Application::Updator.new(stub) }

  describe "#git?" do

    it "is a git repo" do
      subject.stub(:git_status) { "# On branch master\nnothing to commit (working directory clean)" }
      subject.should be_git
    end

    it "is not a git repo" do
     subject.stub(:git_status) { "fatal: Not a git repository (or any of the parent directories): .git" }
     subject.should_not be_git
    end
  end

  describe "#dirty?" do

    it "is clean" do
      subject.stub(:git_status) { "# On branch master\nnothing to commit (working directory clean)" }
      subject.should_not be_dirty
    end

    it "is clean" do
      subject.stub(:git_status) { "# On branch master\n# Changes to be committed:" }
      subject.should be_dirty
    end

  end
end
