class PebbleFile

  attr_reader :pebbles

  def initialize
    @pebbles = []
  end

  def load(file_name)
    raise ArgumentError, "Please verify that #{name} exists and call me back." unless File.basename(file_name)
    @pebbles = DSL.load(file_name).pebbles
  end


  class DSL

    attr_reader :pebbles

    def initialize
      @pebbles = []
    end

    def self.load(file_name)
      dsl = DSL.new
      dsl.instance_eval(File.read(file_name), file_name)
      dsl
    end

    def pebble(name, options = {})
      @pebbles << PebbleDeclaration.new(name, options)
    end

  end


  class PebbleDeclaration

    attr_reader :name
    attr_reader :options

    def initialize(name, options)
      @name = name
      @options = options
    end

  end


end