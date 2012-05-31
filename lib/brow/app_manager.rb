# encoding: utf-8
# Discover configuration and manage web servers

require 'timeout'

class Brow::AppManager
  attr_reader :root

  def initialize(root = nil)
    @root = (root || ENV['HOME']+"/.brow").chomp("\n")
  end

  def find(name)
    applications[name]
  end

  def servers
    return @servers if @servers
    @servers = {}
    Brow::ServerProcess.find_all.each do |server|
      @servers[server.name] = server
    end
    @servers
  end

  def reload_servers
    @servers = nil
  end

  def applications
    return @applications if @applications
    @applications = {}
    Brow::Application.discover(@root).each do |app|
      handle_duplicate_app_name_error(app, @applications[app.name]) unless @applications[app.name].nil?
      @applications[app.name] = app
    end
    @applications
  end

  def application_dirs
    applications.values.map(&:root)
  end

  def default_application_name
    default_config_file_name = File.join(@root, 'default')
    if File.exist?(default_config_file_name)
      name = File.read(default_config_file_name).strip
      if application_names.include?(name)
        return name
      end
    end
  end

  def application_names
    applications.keys
  end

  def kill_all
    to_kill = servers.keys
    puts "Stopping #{to_kill.join(', ')}" unless to_kill.empty?
    Brow::ServerProcess.kill_all
  end

  def running
    reload_servers
    servers.values.map(&:name).uniq
  end

  def launch_all
    (application_names-running).each do |name|
      launch(name)
    end
  end

  def running?(name)
    running.include?(name)
  end

  def launch(name)
    puts "  + #{name}"
    Brow::ServerProcess.launch(applications[name].root)
  end

  def kill(name)
    puts "  - #{name}"
    Brow::ServerProcess.kill(name)
  end

  def restart(name, hard = false)
    unless hard
      puts "Reloading #{name}"
      Brow::ServerProcess.graceful_restart(name)
    else
      kill(name) if running?(name)
      Timeout::timeout(5) do
        sleep 1 while running?(name)
      end
      launch(name)
    end
    true
  end

  def socket_for(name)
    Brow::ServerConfig.socket_for_service(name)
  end

  def sockets
    running.map{|name| socket_for(name)}
  end

  def dependencies(name)
    application = find(name)
    raise ArgumentError, "\"#{name}\" is not a known pebble. Is it in your .brow folder?" unless application
    PebbleFile.dependencies(application.root) do |service_name|
      find(service_name).root
    end
  end

  private

  def handle_duplicate_app_name_error(app1, app2)
    $stderr.puts "Fatal: multiple applications with same name configured. Remove or rename one."
    $stderr.puts "  #{app1.root}"
    $stderr.puts "  #{app2.root}"
    exit 1
  end
end
