require 'yaml'

# Enumerating, killing and launching individual web servers
class Brow::ServerProcess
  attr_reader :pid, :pwd, :name

  SOCKET_NAME_PREFIX="brow-service-"

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

  def self.socket_for_service(name)
    "/tmp/#{SOCKET_NAME_PREFIX}#{name}.sock"
  end

  def self.service_name(pwd)
    File.basename(pwd)
  end

  def self.generate_unicorn_config(pwd, file_name)
    options = {
      :pwd => pwd, 
      :socket => socket_for_service(service_name(pwd)),
      :pidfile => "/tmp/brow-#{service_name(pwd)}.pid"
    }

    config_path = File.join(pwd, ".brow")
    if File.exist?(config_path)
      config = YAML.load(File.open(config_path)) || {}
      if (workers = config['workers'])
        options[:workers] = workers.to_i
      end
    end
    
    File.open(file_name, 'w') do |f|
      f.write(Brow::UnicornConfig.generate(options)) 
    end
  end

  def self.generate_site_config(pwd, file_name)
    env = "development"
    name = service_name(pwd)
    memcached = nil
    File.open(file_name, 'w') do |f|
      f.write(ERB.new(File.read("#{HOME}/lib/brow/templates/site.rb.erb")).result(binding))
    end
  end

  def self.launch(pwd)
    service_name = service_name(pwd)
    config_file_name = "/tmp/brow-#{service_name(pwd)}-unicorn.config.rb"

    generate_unicorn_config(pwd, config_file_name)
    generate_site_config(pwd, "#{pwd}/config/site.rb")

    result = Brow::ShellEnvironment.exec(
      "BUNDLE_GEMFILE=#{pwd}/Gemfile bundle exec unicorn -D --config-file #{config_file_name} config.ru", pwd)
    puts result unless result.empty?

    socket_for_service(service_name(pwd))
  end

end
