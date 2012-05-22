# Generates unicorn config files

class Brow::ServerConfig
  SOCKET_NAME_PREFIX="brow-service-"

  def initialize(pwd)
    @pwd = pwd.chomp('/')
    config = load_config
    @name = File.basename(pwd)
    @socket = "/tmp/#{SOCKET_NAME_PREFIX}#{@name}.sock"
    @pidfile = "/tmp/brow-#{@name}.pid"
    @workers = config['workers'] || 4
  end

  def load_config    
    config_path = File.join(@pwd, ".brow")    
    return {} unless File.exist?(config_path)
    YAML.load(File.open(config_path)) || {}
  end

  def template(name)
    ERB.new(File.read("#{HOME}/lib/brow/templates/#{name}"), nil, '-') # <- '-' specifies trim mode
  end

  def unicorn_config
    appdir = @pwd
    workers = @workers
    socket = @socket
    pidfile = @pidfile
    name = @name
    template('unicorn.rb.erb').result(binding) # <-- binding!
  end

  def unicorn_config_file_name
    "/tmp/brow-#{@name}-unicorn.config.rb"
  end

  def save_unicorn_config    
    File.open(unicorn_config_file_name, 'w') do |f|
      f.write(unicorn_config) 
    end
  end

  def site_config_file_name
    "#{@pwd}/config/site.rb"
  end

  def site_config
    env = "development"
    name = @name
    memcached = nil
    template('site.rb.erb').result(binding)
  end

  def save_site_config
    File.open(site_config_file_name, 'w') do |f|
      f.write(site_config)
    end
  end

  def save_configs
    save_unicorn_config
    save_site_config
  end

  def launch
    save_configs
    result = Brow::ShellEnvironment.exec(
      "BUNDLE_GEMFILE=#{@pwd}/Gemfile bundle exec unicorn -D --config-file #{unicorn_config_file_name} config.ru", @pwd)
    puts result unless result.empty?
    @socket
  end
end
