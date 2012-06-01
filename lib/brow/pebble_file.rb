require 'pathname'

class PebbleFile

  attr_accessor :pebbles, :pebble_file_path

  def initialize
    @pebbles = {}
    @pebble_file_path = ""
  end

  def load(file_name)
    DSL.load(file_name, self)
  end


  def self.dependencies(root_path, deps_so_far, &block)
    pebble_file = PebbleFile.new
    DSL.load(root_path, pebble_file)
    pebble_file.pebbles.keys.each do |dependency|
      unless deps_so_far.include? dependency
        deps_so_far << dependency

        begin
          root_path = yield(dependency)
        rescue StandardError => e
          raise "Ouch! Dependecy list in #{pebble_file.pebble_file_path} contains reference to '#{dependency}' which is not a known application."
        end

        self.dependencies(root_path, deps_so_far, &block)
      end
    end
    return deps_so_far
  end


  class DSL

    def initialize(pebble_file)
      @pebble_file = pebble_file
    end

    def self.load(file_name, pebble_file)
      pathname = Pathname.new(file_name)
      pathname = pathname + "Pebblefile" unless pathname.basename == "Pebblefile"
      file_name = pathname.to_s
      return unless File.exists?(file_name)
      dsl = DSL.new(pebble_file)
      dsl.instance_eval(File.read(file_name), file_name)
      pebble_file.pebble_file_path = file_name
      nil
    end

    def pebble(name, options = {})
      @pebble_file.pebbles[name] = options
    end

  end


end