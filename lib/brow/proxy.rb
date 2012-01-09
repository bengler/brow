# Handles configuring and starting/stopping nginx

class Brow::Proxy
  attr_reader :last_validation_output

  NGINX_CONFIG_FILE_LOCATION = '/tmp/brow-nginx-dummy.conf'

  def initialize(app_manager)
    unless `nginx -v 2>&1` =~ /version/
      puts "Please install nginx"
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
          :pwd => @app_manager.applications[app].root })
    end
    nginx_config.generate
  end

  def write_config(filename)
    File.open(filename, 'w') {|f| f.write(generate_config) }
  end

  def valid_config?
    write_config('/tmp/brow-nginx-preflight.conf')
    @last_validation_output = `sudo nginx -t -c /tmp/brow-nginx-preflight.conf 2>&1`
    !!(@last_validation_output =~ /test is successful\n/)
  end

  def start
    write_config(NGINX_CONFIG_FILE_LOCATION)
    `sudo nginx -c #{NGINX_CONFIG_FILE_LOCATION}`
  end

  def reload
    write_config(NGINX_CONFIG_FILE_LOCATION)
    `sudo nginx -c #{NGINX_CONFIG_FILE_LOCATION} -s reload`
  end

  def stop
    `sudo nginx -c #{NGINX_CONFIG_FILE_LOCATION} -s quit`
  end

  def running?
    `ps -ax | grep nginx`.scan(NGINX_CONFIG_FILE_LOCATION).size > 0
  end

end
