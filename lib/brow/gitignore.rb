# Manages .gitignore

class Brow::Gitignore

  attr_reader :gitignore
  def initialize(pwd)
    @gitignore = "#{pwd.chomp('/')}/.gitignore"
  end

  def ignored?(file)
    ignored.any? {|line| line =~ /#{file}$/ && !line.start_with?('#')}
  end

  def ignore(file)
    ignored << file unless ignored?(file)
  end

  def ignored
    @ignored ||= FileUtils.touch(gitignore) && File.read(gitignore).split("\n")
  end

  def write
    File.open(gitignore, 'w') do |file|
      file.puts ignored.join("\n")
    end
  end
end
