require 'brow/gitignore'

describe Brow::Gitignore do

  subject { Brow::Gitignore.new('spec/fixtures/ignores/') }

  context "when not ignored" do
    specify { subject.ignored?('somethingvisible').should be_false }

    it "ignores it" do
      subject.ignore('somethingvisible')
      subject.ignored.select {|file| file == 'somethingvisible'}.size.should eq(1)
    end

    context "when commented out" do
      specify { subject.ignored?('commentedout').should be_false }
    end
  end

  context "when ignored" do

    specify { subject.ignored?('ignoredstuff').should be_true }
    specify { subject.ignored?('ignorablestuff').should be_true }
    specify { subject.ignored?('path/to/ignorablestuff').should be_true }
    specify { subject.ignored?('lastthing').should be_true }

    it "doesn't add it again" do
      was_ignored = subject.ignored.dup
      subject.ignore('ignoredstuff')
      subject.ignored.should eq(was_ignored)
    end
  end

  describe "writes the ignore file" do
    let(:path) { 'spec/fixtures/' }
    let(:file) { 'spec/fixtures/.gitignore' }
    subject { Brow::Gitignore.new(path) }

    before(:each) { FileUtils.rm(file) if File.exists?(file) }
    after(:each) { FileUtils.rm(file) if File.exists?(file) }

    it "writes" do
      subject.ignore('one')
      subject.ignore('two')
      subject.write
      File.read('spec/fixtures/.gitignore').should eq("one\ntwo\n")
    end

  end
end
