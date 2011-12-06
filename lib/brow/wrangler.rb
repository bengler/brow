# Practically the command line tool as a class

class Brow::Wrangler
  attr_reader :app_manager, :proxy

  ROOT_PATH = "#{ENV['HOME']}/.brow"

  def initialize
    @app_manager = Brow::AppManager.new
    @proxy = Brow::Proxy.new(@app_manager)
  end

  def ensure_brow_folders
    ensure_folder_exists(ROOT_PATH)
  end

  def up
    puts "Releasing all unicorns ..."
    @app_manager.launch_all

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
    Brow::HostsFile.update(@app_manager.application_names)
    
    puts "Done. Stand by for headcount."
    assert_all_apps_running
    assert_nginx_running

    puts "Yay! All systems go"
  end

  def down
    puts "Killing nginx"
    @proxy.stop if @proxy.running?
    puts "Giving all unicorns a break ..."
    @app_manager.kill_all
    assert_all_apps_stopped
  end

  def restart(app_name, hard = false)
    unless @app_manager.application_names.include?(app_name)
      puts "#{app_name} who?"
      return
    end

    unless @app_manager.running.include?(app_name)
      puts "#{app_name} is not running"
      return
    end

    begin
      @app_manager.restart(app_name, hard)
    rescue Timeout::Error
      puts "Sorry. Failed to still #{app_name}."
    end

    assert_all_apps_running([app_name])
  end

  def restart_all(hard = false)
    @app_manager.application_names.each do |name|
      restart(name, hard)
    end
  end

  def watch
    Brow::Watcher.new(Brow::AppManager.new).start
  end

  def assert_all_apps_stopped
    begin
      Timeout.timeout(10) do
        sleep 1 until @app_manager.running.empty?
      end
      return true
    rescue Timeout::Error
      puts "Fatal: #{@app_manager.running.join(', ')} refuse to take a breather."
      exit 1
    end
  end

  def assert_all_apps_running(application_names = nil)
    application_names ||= @app_manager.application_names
    begin
      Timeout.timeout(10) do
        sleep 0.5 until (application_names - @app_manager.running).empty?
      end
      return true
    rescue Timeout::Error
      missing = application_names - @app_manager.running
      puts "Warning: #{missing.join(', ')} has failed to launch." 
      exit 1
    end
  end

  def assert_nginx_running
    unless @proxy.running?
      puts "Warning: Nginx is not running"
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