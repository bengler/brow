class Brow::Proxy
  def initialize(services)
    begin
      `nginx -v`
    rescue Errno::ENOENT
      puts "Brow requires Nginx"
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

  def validate_config
    File.open('/tmp/nginx-dummy.conf', 'w') {|f| f.write(config) }
    `nginx -t -c /tmp/nginx-dummy.conf 2>&1`
  end

  def valid_config?
    !!(validate_config =~ /test is successful\n/)
  end

end