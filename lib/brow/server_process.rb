require 'yaml'

# Enumerating, killing and launching individual web servers
class Brow::ServerProcess
  attr_reader :pid, :pwd, :name

  def initialize(pid)
    @pid = pid
    pwd_line = `lsof -a -p #{pid} -d cwd -Fn`.split(/\n/).find{|l| l =~ /^n/}
    @pwd = pwd_line[1..-1].chomp("\n") if pwd_line
    @name = File.basename(@pwd).downcase if @pwd
  end

  def socket
    socket_for_service(@name)
  end

  def kill
    `kill -8 #{@pid}`
  end

  def self.find_all
    pids = `$(which ps) ax | grep 'unicorn master'`.split("\n").map{|line| line.scan(/^\s*(\d+).*brow-.*-unicorn/)}.flatten
    pids.map do |pid|
      self.new(pid)
    end
  end

  def self.find_by_name(name)
    find_all.find { |proc| proc.name == name }
  end

  def self.kill_all
    find_all.each(&:kill)
  end

  def self.kill(name)
    find_all.each do |server|
      server.kill if server.name == name
    end
  end

  def self.old_unicorns
    `$(which ps) ax | grep 'unicorn master (old)'`.split("\n").map{|line| line.scan(/^\s*(\d+).*#{SOCKET_NAME_PREFIX}/)}.flatten
  end

  def self.kill_old_unicorns
    old_unicorns.map do |pid|
      `kill -s QUIT #{pid}`
    end.size
  end

  def self.graceful_restart(name)
    if proc = find_by_name(name)
      `kill -s USR2 #{proc.pid}`
      sleep 0.5
      Timeout::timeout(5) do        
        sleep 0.5 until kill_old_unicorns == 0
      end
      return true
    end
    false
  end

  def self.launch(pwd)
    Brow::ServerConfig.new(pwd).launch
  end

end
