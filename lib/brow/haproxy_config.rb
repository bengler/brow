module Brow::HAProxyConfig
  CONFIG_FILE = "/tmp/brow/haproxy/haproxy.cfg"
  PID = "/tmp/brow/haproxy.pid"

  def self.generate(options)
    FileUtils.mkdir_p("/tmp/brow/haproxy")
    File.open(CONFIG_FILE, 'w') do |f|
      f.write(self.config(options[:apps_paths], options[:default]))
    end
  end

  def self.config(apps_paths, default_name = nil)
    server_port = Brow::NginxConfig::PORT
    pidfile = PID
    template("haproxy.cfg.erb").result(binding)
  end

  def self.template(name)
    ERB.new(File.read("#{HOME}/lib/brow/templates/#{name}"), nil, '-') # <- '-' specifies trim mode
  end
end
