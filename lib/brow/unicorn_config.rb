# Generates unicorn config files

class Brow::UnicornConfig
  attr_accessor :pwd, :workers, :timeout, :service_name

  def initialize(options)
    @pwd = options[:pwd]
    @workers = options[:workers] || 4
    @timeout = options[:timeout] || 5
    @service_name = options[:service_name] || File.basename(@pwd)
  end

  def generate
    <<-END
      worker_processes #{@workers}
      working_directory "#{@pwd}"
      timeout #{@timeout}
      stderr_path "/tmp/brow-#{@service_name}.stderr.log"
      stdout_path "/tmp/brow-#{@service_name}.stdout.log"

      preload_app false

      before_fork do |server, worker|
        Hupper.release! if defined?(Hupper)
        sleep 1
      end

      after_fork do |server, worker|
        Hupper.initialize! if defined?(Hupper)
      end
    END
  end
end

