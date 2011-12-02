require 'guard'
require 'timeout'
require 'thread'

class Brow::Watcher
  attr_reader :restart_queue

  IGNORE_FILES = /\.log$/

  def initialize(services)
    @services = services
    @restart_queue = Queue.new
    @growl_enabled = !`which growlnotify`.empty?
  end

  def start(service_names = nil)
    service_names ||= @services.service_names

    rails_services, service_names = service_names.partition do |service|
      @services.is_rails_app?(service)
    end
    unless rails_services.empty?
      puts "Found rails in Gemfile, not watching: #{rails_services.join(', ')}"
    end

    service_names.each { |service| watch(service) }
    puts "Watching #{service_names.join(', ')}"
    puts "(Install growlnotify (http://growl.info/downloads.php) to be notified of restarts in style.)" unless @growl_enabled
    begin
      while true
        service = @restart_queue.pop
        notification('Brow', "Restarting #{service}")
        @services.restart(service)
      end
    rescue Interrupt
      puts "Signing off"
    end
  end

  def watch(service_name)
    listener = Guard::Listener.select_and_init(@services.pwd_for(service_name))
    last_change_event = nil
    listener.on_change do |files|
      files.reject!{ |f| f =~ IGNORE_FILES }
      unless files.empty?
        puts "(!) #{files.join(', ')}"
        last_change_event = Time.new
      end
    end

    Thread.new do
      while true
        sleep 1 until !last_change_event.nil?
        sleep 1 until Time.now-last_change_event > 2
        last_change_event = nil
        @restart_queue << service_name
      end
    end
    Thread.new do
      listener.start
    end
  end

  def notification(title, text)
    icon = File.expand_path("#{File.dirname(__FILE__)}/../../asset/icon.png")
    `growlnotify --message "#{text}" --image #{icon} #{title}` if @growl_enabled
  end
end
