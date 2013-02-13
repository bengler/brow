# Handles configuring and starting/stopping nginx and haproxy

# TODO: HAProxy and Nginx handled as conjoined twins in this class. At some point
# this will probably have to be factored into separate classes.

class Brow::Proxy
  attr_reader :last_validation_output

  def initialize(app_manager)
    unless `nginx -v 2>&1` =~ /version/
      puts "Please install nginx (brow setup)"
      exit 1
    end
    unless `haproxy -v 2>&1` =~ /version/
      puts "Please install haproxy (brow setup)"
      exit 1
    end
    @app_manager = app_manager
  end

  def generate_config
    nginx_config = Brow::NginxConfig.new
    @app_manager.application_names.each do |app|
      nginx_config.declare_application(
        app,
        { :socket => @app_manager.socket_for(app),
          :pwd => @app_manager.applications[app].root },
        :default => (@app_manager.default_application_name == app))
    end
    nginx_config.generate
    Brow::HAProxyConfig.generate(
      :names => @app_manager.application_names,
      :default => @app_manager.default_application_name)
  end

  def valid_config?
    generate_config    
    nginx_validation = `nginx -t -c #{Brow::NginxConfig::CONFIG_FILE} 2>&1`
    nginx_ok = nginx_validation =~ /test is successful/
    unless nginx_ok
      puts "Nginx config did not validate"
      puts nginx_validation 
    end
    haproxy_validation = `sudo haproxy -f #{Brow::HAProxyConfig::CONFIG_FILE} -c 2>&1`
    haproxy_ok = haproxy_validation =~ /Configuration file is valid/
    unless haproxy_ok
      puts "HAProxy config did not validate"
      puts haproxy_validation 
    end
    nginx_ok && haproxy_ok
  end

  def start
    generate_config
    `nginx -c #{Brow::NginxConfig::CONFIG_FILE}`
    `sudo touch #{Brow::HAProxyConfig::PID}; sudo haproxy -f #{Brow::HAProxyConfig::CONFIG_FILE} -sf $(<#{Brow::HAProxyConfig::PID})`
  end

  def reload
    generate_config
    puts `nginx -c #{Brow::NginxConfig::CONFIG_FILE} -s reload`
    puts `sudo touch #{Brow::HAProxyConfig::PID}; sudo haproxy -f #{Brow::HAProxyConfig::CONFIG_FILE} -sf $(<#{Brow::HAProxyConfig::PID})`
  end

  def stop
    `nginx -c #{Brow::NginxConfig::CONFIG_FILE} -s quit`
    `sudo kill $(<#{Brow::HAProxyConfig::PID})`
  end

  def running?
    process_running?("nginx", Brow::NginxConfig::PID) &&
      process_running?("haproxy", Brow::HAProxyConfig::PID)
  end

  private

    def process_running?(name, pid_path)
      if (pid = File.read(pid_path).strip rescue nil)
        pids = `pgrep -f #{name}`.strip.split("\n").include?(pid.to_s)
      else
        false
      end
    end

end