require 'guard'
require 'timeout'
require 'thread'

class Brow::Watcher
  attr_reader :restart_queue

  def initialize(services)
    @services = services
    @restart_queue = Queue.new
  end

  def start    
    @services.service_names.each { |service| watch(service) }
    while true
      service = @restart_queue.pop
      @services.restart(service)
    end
  end 

  def watch(service_name)
    puts "Watching #{service_name}"
    listener = Guard::Listener.select_and_init(@services.pwd_for(service_name))
    last_change_event = nil
    listener.on_change do |file|
      last_change_event = Time.new
    end

    Thread.new do
      while true
        sleep 1 until !last_change_event.nil?
        sleep 1 until Time.now-last_change_event > 5
        last_change_event = nil       
        @restart_queue << service_name
        puts @restart_queue.inspect
      end
    end
    Thread.new do
      listener.start
    end
  end
end