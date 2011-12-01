# Handles configuring and starting/stopping nginx

class Brow::Proxy
  attr_reader :last_validation_output

  NGINX_CONFIG_FILE_LOCATION = '/tmp/brow-nginx-dummy.conf'

  def initialize(services)
    unless `nginx -v 2>&1` =~ /^nginx\:/
      puts "Please install nginx"
      exit 1
    end
    @services = services
  end

  def config
    nginx_config = Brow::NginxConfig.new
    @services.pebble_names.each do |pebble|
      nginx_config.declare_pebble(pebble, {:socket => @services.socket_for(pebble), :pwd => @services.pwd_for(pebble)})
    end
    @services.app_names.each do |app|
      nginx_config.declare_app(app, {:socket => @services.socket_for(app), :pwd => @services.pwd_for(app)})
    end
    nginx_config.config
  end

  def write_config(filename)
    File.open(filename, 'w') {|f| f.write(config) }
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