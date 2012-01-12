require 'guard'
require 'timeout'
require 'thread'

class Brow::Watcher
  attr_reader :restart_queue

  IGNORE_FILES = /\.log$|\.git|\.js\b|\.s[ac]ss$|\.css$/

  def initialize(app_manager)
    @app_manager = app_manager
    @restart_queue = Queue.new
    @growl_enabled = !`which growlnotify`.empty?
    @notify_enabled = !`which notify-send`.empty?
  end

  def start(application_names = nil)
    rails_services, to_watch = @app_manager.applications.values.partition do |app| 
      app.rails?
    end

    to_watch.map(&:name).each { |service| watch(service) }
    puts "(Not watching #{rails_services.map(&:name).join(', ')} because Rails takes care of its own reloading.)" unless rails_services.empty?

    if to_watch.empty? 
      puts "Nothing to watch :-("
      exit 0
    end

    puts "Watching #{to_watch.map(&:name).join(', ')}."

    if `uname` =~ /^Darwin/
      puts "(Install growlnotify (http://growl.info/downloads.php) to be notified of restarts in style.)" unless @growl_enabled 
    else
      puts "(Install libnotify-bin (sudo apt-get install libnotify-bin) to be notified of restarts in style.)" unless @notify_enabled
    end
    puts

    begin
      while true
        service = @restart_queue.pop
        @app_manager.restart(service)
        notification('Brow', "Reloaded #{service}")
      end
    rescue Interrupt
      puts "Signing off"
    end
  end

  def watch(service_name)
    listener = Guard::Listener.select_and_init(@app_manager.applications[service_name].root)
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
    icon = File.expand_path("#{File.dirname(__FILE__)}/../../asset/icon48.png")
    if @growl_enabled
      `growlnotify --message "#{text}" --image #{icon} #{title}` 
    elsif @notify_enabled
    `notify-send --icon=#{icon} "#{title}" "#{text}"`
    end
  end
end
