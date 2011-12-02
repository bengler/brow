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

      hupper_enabled = !!defined?(Hupper)
      preload_app hupper_enabled
      unless defined?(Hupper)
        $stderr.puts "Brow warning: Running your app in legacy mode. Please use Hupper to handle connections. (https://github.com/origo/hupper)"
      end

      before_fork do |server, worker|
        Hupper.release! if hupper_enabled
        sleep 1
      end

      after_fork do |server, worker|
        Hupper.initialize! if hupper_enabled
      end
    END
  end
end

