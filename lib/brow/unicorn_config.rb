# Generates unicorn config files

module Brow::UnicornConfig
  def self.generate(params)
    appdir = params[:pwd].chomp('/')
    workers = params[:workers] || 4
    socket = params[:socket]
    pidfile = params[:pidfile]
    name = params[:service_name] || File.basename(appdir)
    ERB.new(File.read("#{HOME}/lib/brow/templates/unicorn.rb.erb")).result(binding) # <-- binding?!?!?!
  end
end

