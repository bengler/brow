# Enumerating, killing and launching individual web servers

class Brow::ServerProcess
  attr_reader :pid, :pwd, :name

  def initialize(pid)
    @pid = pid
    @pwd = `lsof -a -p #{pid} -d cwd -Fn`.chomp("\n")
    @name = File.basename(@pwd)
  end

  def kill
    `kill -s QUIT #{@pid}`
  end

  def self.find_all
    pids = `ps -ax | grep 'unicorn master'`.split("\n").map{|line| line.scan(/^(\d+).*\d\:\d\d\.\d\d unicorn/)}.flatten
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
    `ps -ax | grep 'unicorn master (old)'`.split("\n").map{|line| line.scan(/^(\d+).*\d\:\d\d\.\d\d unicorn/)}.flatten
  end

  def self.kill_old_unicorns
    old_unicorns.map do |pid|
      `kill -s QUIT #{pid}`
    end.size
  end

  def self.graceful_restart(name)
    if proc = find_by_name(name)
      `kill -s HUP #{proc.pid}`
      sleep 0.5 until old_unicorns.size > 0
      sleep 0.5 until kill_old_unicorns == 0
      return true
    end
    false
  end

  def self.launch(pwd, socket = nil)
    socket ||= "brow_app_#{rand(2**128).to_s(36)}"
    result = Brow::ShellEnvironment.exec(
      "BUNDLE_GEMFILE=#{pwd}/Gemfile bundle exec unicorn -D -l #{socket} config.ru", pwd)
    puts result unless result.empty?
    socket
  end

end