# Represents an application configured in the .brow folder

class Brow::Application
  attr_reader :root, :name, :paths

  def initialize(root)
    @root = root
    @name = File.basename(@root).downcase
    @paths = extract_paths
    @paths << "/api/#{name}" if @paths.empty?
  end

  def rails?
    @rails ||= gem_rails_configured?
  end

  # Extract application top-level map paths from config.ru
  # Note that top-level is defined as unindented map-statements
  def extract_paths
    File.read(File.join @root, "config.ru").scan(/^map[( ]*['"]([^'"]+)/).flatten
  end

  def update(&block)
    Brow::Application::Updator.new(self).update(&block)
  end

  # Discover all apps configured under the provided root folder
  def self.discover(root)
    app_folders(root).map { |folder| Brow::Application.new(File.realpath(folder)) }
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
