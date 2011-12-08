# Writes the nginx config files

class Brow::NginxConfig

  def initialize
    @apps = {}
  end
  
  def declare_application(name, config)
    raise "Must specify socket" unless config[:socket]
    puts "Warning: No pwd supplied for app #{name}" unless config[:pwd]
    @apps[name] = config
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
    }
    """
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
      proxy_pass http://#{pebble_name};
      proxy_set_header X-Forwarded-Host $host;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    """
  end

  def server(name)    
    socket = @apps[name]
    result = """
      listen 80;
      server_name #{name}.dev;
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
      location / {
        proxy_set_header X-Forwarded-Host $host;
        ssi on;
        if (!-f $request_filename) {
          proxy_pass http://#{name};
        }
      }
    """

    """
    server {
      #{result}
    }
    """
  end

  def locate_mime_types
    case `which nginx` 
    when /^\/opt/
      files = `port contents nginx`.split("\n").map(&:strip)
    when /^\/usr/
      files = `brew list nginx`.split("\n")
    else
      puts "Nginx must be installed via either homebrew or macports"
      exit 1
    end
    files.find{ |file| file =~ /mime.types$/ }
  end

end