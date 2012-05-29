# Represents an application configured in the .brow folder

class Brow::Application
  attr_reader :root, :name

  def initialize(root)
    @root = root
    @name = File.basename(@root).downcase
  end

  def rails?
    @rails ||= gem_rails_configured?
  end

  def update(&block)
    Brow::Application::Updator.new(self).update(&block)
  end

  # Discover all apps configured under the provided root folder
  def self.discover(root)
    app_folders(root).map { |folder| Brow::Application.new(folder) }
  end

  def self.app_folders(root)
    `find -L #{root} -iname config.ru`.split("\n").map do |line|
      File.dirname(line)
    end
  end

  private

  def gem_rails_configured?
    gemfile = @root+"/Gemfile"
    unless File.exist?(gemfile)
      $stderr.puts "Warning: #{@name} has no Gemfile. Wtf?"
      return false
    end
    File.read(gemfile).split("\n").each do |line|
      return true if line =~ /^\s*gem\s+.rails./
    end
    false
  end

end
