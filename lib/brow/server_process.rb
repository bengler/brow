# Enumerating, killing and launching individual web servers

class Brow::ServerProcess
  attr_reader :pid, :pwd, :name

  def initialize(pid)
    @pid = pid
    @pwd = `lsof -a -p #{pid} -d cwd -Fn`.chomp("\n")
    @name = File.basename(@pwd)
  end

  def kill
    `kill -8 #{@pid}`
  end

  def self.find_all
    pids = `ps -ax | grep unicorn`.split("\n").map{|line| line.scan(/^(\d+).*\d\:\d\d\.\d\d unicorn/)}.flatten
    pids.map do |pid|
      self.new(pid)
    end
  end

  def self.kill_all
    find_all.each(&:kill)
  end

  def self.kill(name)
    find_all.each do |server|
      server.kill if server.name == name
    end
  end

  def self.launch(pwd, socket = nil)
    socket ||= "brow_app_#{rand(2**128).to_s(36)}"
    result = `
      cd #{pwd}
      BUNDLE_GEMFILE=#{pwd}/Gemfile bundle exec unicorn -D -l #{socket} config.ru
    `
    socket
  end

end