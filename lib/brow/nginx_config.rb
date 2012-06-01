class Brow::NginxConfig
  NGINX_CONFIG_FILE = "/tmp/brow/nginx/nginx.conf"
  NGINX_INCLUDE_PATH = "/tmp/brow/nginx/include"
  NGINX_PORT = 8000

  attr :apps

  def initialize
    @apps = {}
    @next_port = 8000

  end

  def declare_application(name, config, options = {})
    raise "Must specify socket" unless config[:socket]
    puts "Warning: No pwd supplied for app #{name}" unless config[:pwd]
    @apps[name] = config    
    @default_application_name = name if options[:default]
  end

  def generate
    puts "Creating dirs (as #{ENV['USER']}"
    ['/tmp/brow', '/tmp/brow/nginx', '/tmp/brow/nginx/include'].each do |dir|
      Dir.mkdir(dir) unless File.exists?(dir)
    end

    puts "Writing main nginx config"
    File.open(NGINX_CONFIG_FILE, 'w') do |f|
      f.write(main_config)
    end
    @apps.keys.each do |appname|
      puts "Writing vhost-config for #{appname}"
      File.open(File.join(NGINX_INCLUDE_PATH, "#{appname}.conf"), 'w') do |f|
        f.write(vhost_config(appname, @apps[appname]))
      end
    end
  end

  def main_config
    user = 'nobody'
    errorlog = "/dev/null"
    pidfile = "/tmp/brow/nginx.pid"
    accesslog = "/dev/null"
    fqdn = `hostname`.chomp
    mimetypes = File.expand_path(File.join(File.dirname(__FILE__), 'templates/mime.types'))
    includepath = "/tmp/brow/nginx/include/*"
    template('nginx.conf.erb').result(binding) # <-- binding!
  end

  def vhost_config(appname, options)
    unicorn = options[:socket]
    port = NGINX_PORT
    name = appname
    documentroot = File.join(options[:pwd], '/public')
    accesslog = "/tmp/nginx_access.log" #"/dev/null"
    errorlog = "/tmp/nginx_error.log" #"/dev/null"
    ssi = true
    redirect = ''
    publicexpires = '5s'
    htpasswd = false
    config = ''
    aliases = []
    maxupload = ''
    template('vhost.conf.erb').result(binding) # <-- binding!
  end

  def template(name)
    ERB.new(File.read("#{HOME}/lib/brow/templates/#{name}"), nil, '-') # <- '-' specifies trim mode
  end

end