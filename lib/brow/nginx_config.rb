# Writes the nginx config files

class Brow::NginxConfig

  def initialize
    @apps = {}
  end
  
  def declare_application(name, config, options = {})
    raise "Must specify socket" unless config[:socket]
    puts "Warning: No pwd supplied for app #{name}" unless config[:pwd]
    @apps[name] = config
    if options[:default]
      @default_application_name = name
    end
  end

  def preamble    
    """
    worker_processes 4;
    pid /tmp/brow-nginx.pid;
    working_directory /tmp;
    error_log /tmp/brow-nginx-error.log crit;

    events {
      worker_connections 1024;
    }

    """
  end

  def generate
    result = preamble   
    result << """    
    http {
      sendfile on;
      tcp_nopush on;
      tcp_nodelay on;
      keepalive_timeout 60;
      include #{locate_mime_types};
      default_type text/plain;
      charset utf-8;
      gzip off;
      client_body_temp_path /tmp/client_body_temp;
      proxy_temp_path /tmp/proxy_temp;
      fastcgi_temp_path /tmp/fastcgi_temp;
      uwsgi_temp_path /tmp/uwsgi_temp;
      scgi_temp_path /tmp/scgi_temp;

      #{upstream}

      #{@apps.keys.map do |name|
        server(name)
      end.join("\n")}
    "
    if @default_application_name
      result << server(@default_application_name, '_')  # Catch all
    end
    result << "\n}"
    result
  end

  def upstream
    @apps.map do |name, options|
      """
      upstream #{name} {
        server unix:#{options[:socket]} fail_timeout=30;
      }
      """
    end.join("\n")
  end

  def pebble_location(pebble_name)
    """
    location /api/#{pebble_name} {
      ssi on;
      ssi_value_length 1024;
      proxy_pass http://#{pebble_name};
      proxy_set_header X-Forwarded-Host $host;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    """
  end

  def server(name, vhost_name = nil)
    vhost_name ||= "#{name}.dev"
    socket = @apps[name]
    result = """
      listen 80 #{'default_server' if vhost_name == '_'};
      client_max_body_size 20M;
      server_name #{vhost_name};
    """

    # Logging and public folder
    if pwd = @apps[name][:pwd]
      result << """
        root #{pwd}/public; # path to static files
        access_log #{pwd}/log/nginx-access.log;
      """
    end

    # Proxy forwarding to all other apps
    (@apps.keys - [name]).each do |name|
      result << pebble_location(name)
    end

    # The actual app
    result << """
      ssi on;
      ssi_value_length 1024;
      
      location ~* \.(css|gif|ico|jpeg|jpg|png)$ {
        try_files $uri @unicorn;
        expires 10m;
      }

      location / {        
        try_files $uri @unicorn;
      }

      location @unicorn {
        proxy_set_header Host $http_host;
        proxy_pass http://#{name};
      }
    """

    """
    server {
      #{result}
    }
    """
  end

  def locate_mime_types
    case `uname`
    when /^Darwin/
      case `which nginx` 
      when /^\/opt/
        files = `port contents nginx`.split("\n").map(&:strip)
      when /^\/usr/
        files = `brew list nginx`.split("\n")
        # New brew puts files here, and is not listed by `brew list`
        unless files.find{ |file| file =~ /mime.types$/ } or
            files.find{ |file| file =~ /mime.types.example$/ }
          files << '/usr/local/etc/nginx/mime.types'
          files << '/usr/local/etc/nginx/mime.types.example'
        end        
      else
        puts "Nginx must be installed via either homebrew or macports"
        exit 1
      end
    else
      case `which nginx` 
      when /^\/usr/
        files = `dpkg -L nginx`.split("\n")
        files += `dpkg -L nginx-common`.split("\n")   # for versions from ppa:nginx/stable
      else
        puts "Nginx must be installed via either dpkg"
        exit 1
      end
    end
    file = files.find{ |file| file =~ /mime.types$/ }
    file ||= files.find{ |file| file =~ /mime.types.example$/ }
  end

end
