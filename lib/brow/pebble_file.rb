require 'pathname'

class PebbleFile

  attr_accessor :pebbles

  def initialize
    @pebbles = {}
  end

  def load(file_name)
    DSL.load(file_name, self)
  end


  def self.dependencies(root_path, &block)
    service_name = Pathname.new(root_path).basename.to_s

    path = yield(service_name)

    pebble_file = PebbleFile.new
    DSL.load(path, pebble_file)
    return pebble_file.pebbles.keys
  end


  class DSL

    def initialize(pebble_file)
      @pebble_file = pebble_file
    end

    def self.load(file_name, pebble_file)
      pathname = Pathname.new(file_name)
      pathname = pathname + "Pebblefile" unless pathname.basename == "Pebblefile"
      file_name = pathname.to_s
      raise ArgumentError, "Please verify that #{file_name} exists" unless File.basename(file_name)

      dsl = DSL.new(pebble_file)
      dsl.instance_eval(File.read(file_name), file_name)
      nil
    end

    def pebble(name, options = {})
      @pebble_file.pebbles[name] = options
    end

  end


end