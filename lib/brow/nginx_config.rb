class Brow::NginxConfig
  CONFIG_FILE = "/tmp/brow/nginx/nginx.conf"
  INCLUDE_PATH = "/tmp/brow/nginx/include"
  PORT = 8000
  PID = "/tmp/brow/nginx.pid"
  REQUIRED_MODULES = ['http_stub_status_module', 'http_gzip_static_module']

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
    FileUtils.mkdir_p("/tmp/brow/nginx/include")
    File.open(CONFIG_FILE, 'w') do |f|
      f.write(main_config)
    end
    @apps.keys.each do |appname|
      File.open(File.join(INCLUDE_PATH, "#{appname}.conf"), 'w') do |f|
        f.write(vhost_config(appname, @apps[appname]))
      end
    end
  end

  def main_config
    user = nil
    errorlog = "/dev/null"
    pidfile = PID
    accesslog = "/dev/null"
    fqdn = `hostname`.chomp
    mimetypes = File.realpath(File.join(File.dirname(__FILE__), 'templates/mime.types'))
    includepath = "/tmp/brow/nginx/include/*"
    template('nginx.conf.erb').result(binding) # <-- binding!
  end

  def vhost_config(appname, options)
    unicorn = options[:socket]
    port = PORT
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
    proxy = options[:socket]
    template('vhost.conf.erb').result(binding) # <-- binding!
  end

  def template(name)
    ERB.new(File.read("#{HOME}/lib/brow/templates/#{name}"), nil, '-') # <- '-' specifies trim mode
  end

end