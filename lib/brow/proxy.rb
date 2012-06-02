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
    Brow::HAProxyConfig.generate(@app_manager.application_names)
  end

  def valid_config?
    generate_config    
    nginx_ok = `nginx -t -c #{Brow::NginxConfig::CONFIG_FILE} 2>&1` =~ /test is successful/
    haproxy_ok = `haproxy -f #{Brow::HAProxyConfig::CONFIG_FILE} 2>&1` =~ /Configuration file is valid/
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
    nginx_running = (`ps ax | grep nginx`.scan(Brow::NginxConfig::CONFIG_FILE).size > 0)
    haproxy_running = (`ps -p $(<#{Brow::HAProxyConfig::PID})`.scan('haproxy').size > 0)
    nginx_running && haproxy_running
  end

end
