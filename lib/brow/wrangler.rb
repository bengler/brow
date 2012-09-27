# Practically the command line tool as a class

class Brow::Wrangler
  attr_reader :app_manager, :proxy

  ROOT_PATH = "#{ENV['HOME']}/.brow"

  def initialize
    @app_manager = Brow::AppManager.new
    @proxy = Brow::Proxy.new(@app_manager)
  end

  def applications
    @app_manager.applications
  end

  def find(app)
    @app_manager.find(app)
  end

  def ensure_brow_folders
    ensure_folder_exists(ROOT_PATH)
  end

  def conflicting_resolver?
    File.exists?('/etc/resolver/dev')
  end

  def up
    if conflicting_resolver?
      puts "WARNING: Delete the file at '/etc/resolver/dev' before you continue."
      return
    end

    inactive = @app_manager.application_names - @app_manager.running
    if inactive.empty?
      puts "All unicorn workers already running"
    else
      puts "Releasing master unicorns for #{inactive.join(", ")} ..."
    end

    @app_manager.launch(*inactive)

    unless @proxy.running?
      puts "Launching nginx."
      unless @proxy.valid_config?
        puts "Unable to launch Nginx/Haproxy"
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

    unless inactive.empty?
      puts "Done. Waiting for unicorn workers."
      @app_manager.wait_for_workers(inactive)
    end
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

    hard = true unless @app_manager.running?(app_name)

    begin
      @app_manager.restart(app_name, hard)
    rescue Timeout::Error
      puts "Sorry. Failed to restart #{app_name}."
    end

    @app_manager.wait_for_workers([app_name]) if hard
  end

  def restart_all(hard = false)
    @app_manager.restart_all(hard)
    @app_manager.wait_for_workers if hard
  end

  def kill(app_name)
    @app_manager.kill(app_name)
    assert_all_apps_stopped([app_name])
  end

  def assert_all_apps_stopped(application_names = nil)
    application_names ||= @app_manager.application_names
    begin
      Timeout.timeout(10) do
        sleep 1 until (@app_manager.running & application_names).empty?
      end
      return true
    rescue Timeout::Error
      puts "Fatal: #{@app_manager.running.join(', ')} refuse to take a breather."
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
