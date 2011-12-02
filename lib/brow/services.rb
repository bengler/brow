# Discover configuration and manage web servers

require 'timeout'

class Brow::Services
  attr_reader :root, :servers

  SOCKET_PREFIX = "brow-service"

  def initialize(root = nil)
    @root = (root || `echo ~/.brow`).chomp("\n")    
    @servers = Brow::ServerProcess.find_all
  end

  def pebble_dirs
    Dir.glob(@root+'/pebbles/*')
  end

  def pebble_names
    pebble_dirs.map do |dir| 
      File.basename(dir) 
    end
  end

  def app_dirs
    Dir.glob(@root+'/apps/*')
  end

  def app_names
    app_dirs.map do |dir| 
      File.basename(dir) 
    end
  end

  def service_dirs
    pebble_dirs + app_dirs
  end

  def service_names
    service_dirs.map do |dir| 
      File.basename(dir) 
    end
  end

  def kill_all
    running.each do |name|
      kill(name)
    end    
  end

  def launch_all
    (service_names-running).each do |name|
      launch(name)
    end
    sleep 1
    running
  end

  def running
    Brow::ServerProcess.find_all.map do |server|
      server.name
    end.uniq
  end

  def running?(name)
    running.include?(name)
  end

  def launch(name)
    puts "  + #{name}"
    Brow::ServerProcess.launch(pwd_for(name))
  end

  def is_rails_app?(name)
    begin
      gemfile = File.join(pwd_for(name), "Gemfile")
      return !open(gemfile).grep(/gem\s+(\"|\')rails(\"|\')/).empty?
    rescue => e
    end
    false
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
      kill(name)
      Timeout::timeout(5) do
        sleep 1 while running?(name)
      end
      launch(name)
    end
    true
  end

  def pwd_for(name)
    service_dirs.find { |path| File.basename(path) == name }
  end

  def socket_for(name)
    Brow::ServerProcess.socket_for_service(name)
  end

  def sockets
    running.map{|name| socket_for(name)}
  end
end
