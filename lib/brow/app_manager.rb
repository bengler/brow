# encoding: utf-8
# Discover configuration and manage web servers

require 'timeout'
require 'open3'

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
    launch(*(application_names-running))
  end

  def launch(*names)
    return if names.empty?

    server_configs = names.map do |name|
      Brow::ServerProcess.server_config_for(applications[name].root)
    end

    server_configs.each(&:prepare)
    commands = server_configs.map(&:launch_command)

    _, wait_threads = Open3.pipeline_r(*commands)

    # Makes the current thread wait until all commands are executed (i.e. the unicorn master process has got its pid)
    wait_threads.map(&:pid)
  end

  def wait_for_workers(names=nil, timeout=20)
    # Waits for workers and puts a notification as the workers are starting up
    Timeout::timeout(timeout) do
      pending = names || application_names
      until pending.empty?
        up = running & pending
        up.each do |name|
          puts "  + #{name}"
        end
        pending -= up
        sleep 0.5
      end
    end
  end

  def running?(name)
    running.include?(name)
  end

  def kill(name)
    Brow::ServerProcess.kill(name)
    puts "  - #{name}"
  end

  def restart(name, hard = false)
    restart_multi([name], hard)
  end

  def restart_all(hard = false)
    restart_multi(application_names, hard)
  end

  def restart_multi(names, hard = false)
    if hard
      running = names.select { |name| running?(name) }
      running.each { |name| kill(name) }
      Timeout::timeout(5) do
        sleep 0.5 while names.any? { |name| running?(name) }
      end
      launch(*names)
    else
      print "Reloading #{names.join(", ")}... "
      names.each do |name|
        Brow::ServerProcess.graceful_restart(name)
      end
      puts "Done."
    end
    true
  end

  def socket_for(name)
    Brow::ServerConfig.socket_for_service(name)
  end

  def sockets
    running.map { |name| socket_for(name) }
  end

  def dependencies(name)
    application = find(name)
    raise StandardError, "Uknown application: #{name}" unless application
    PebbleFile.dependencies(application.root, []) do |service_name|
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
