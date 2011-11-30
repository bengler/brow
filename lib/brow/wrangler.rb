# Launching or killing the entire Brow configuration

class Brow::Wrangler
  attr_reader :services, :proxy

  ROOT_PATH = "#{ENV['HOME']}/.brow"

  def initialize
    @services = Brow::Services.new
    @proxy = Brow::Proxy.new(@services)
  end

  def ensure_brow_folders
    ensure_folder_exists(ROOT_PATH)
    ensure_folder_exists(ROOT_PATH+"/pebbles")
    ensure_folder_exists(ROOT_PATH+"/apps")
  end

  def up
    puts "Launching all unicorns ..."
    @services.launch_all

    unless @proxy.running?
      puts "Launching nginx."
      unless @proxy.valid_config?
        puts "Won't launch Nginx because config did not validate. Nginx had this to say about that:"
        puts @proxy.last_validation_output
        exit 1
      end
      @proxy.start 
    else
      puts "Nginx allready running, reloading config."
      @proxy.reload
    end

    puts "Updating /etc/hosts"
    Brow::HostsFile.update(@services.app_names)
    
    puts "Done. Stand by for headcount."
    sleep 2
    assert_all_services_running
    assert_nginx_running

    puts "Yay! All systems go"
  end

  def down
    puts "Killing nginx"
    @proxy.stop
    puts "Killing all unicorns ..."
    @services.kill_all
  end

  def restart(service_name)
    unless @services.service_names.include?(service_name)
      puts "#{service_name} who?"
      return
    end

    begin
      @services.restart(service_name)
    rescue Timeout::Error
      puts "Sorry. Failed to kill #{service_name}"
    end

    assert_all_services_running
  end

  def assert_all_services_running
    missing = @services.service_names - @services.running
    unless missing.empty?
      puts "Warning: #{missing.join(', ')} has failed to launch." 
      exit 1
    end
  end

  def assert_nginx_running
    unless @proxy.running?
      puts "Nginx is not running. Packing up."
      down
      exit 1
    end
  end

  private

  def ensure_folder_exists(folder)
    unless File.directory?(folder)
      Dir.mkdir(folder) 
    end
  end
end