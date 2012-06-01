# Handles configuring and starting/stopping nginx

class Brow::Proxy
  attr_reader :last_validation_output

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
          :pwd => @app_manager.applications[app].root },
        :default => (@app_manager.default_application_name == app))
    end
    nginx_config.generate
  end

  def valid_config?
    generate_config
    @last_validation_output = `sudo nginx -t -c #{Brow::NginxConfig::NGINX_CONFIG_FILE} 2>&1`
    !!(@last_validation_output =~ /test is successful\n/)
  end

  def start
    generate_config
    `sudo nginx -c #{Brow::NginxConfig::NGINX_CONFIG_FILE}`
  end

  def reload
    generate_config
    `sudo nginx -c #{Brow::NginxConfig::NGINX_CONFIG_FILE} -s reload`
  end

  def stop
    `sudo nginx -c #{Brow::NginxConfig::NGINX_CONFIG_FILE} -s quit`
  end

  def running?
    `ps ax | grep nginx`.scan(Brow::NginxConfig::NGINX_CONFIG_FILE).size > 0
  end

end
