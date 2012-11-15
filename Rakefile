require "bundler/gem_tasks"

ROOT = File.dirname(__FILE__)

namespace :config do
  desc "sync Fetch most recent config files from production environment"
  task :sync do
    puts "Fetching templates"
    `scp abstrakt.park.origo.no:/etc/puppet/modules/app/templates/{site,unicorn}.rb.erb #{ROOT}/lib/brow/templates/`
    `scp abstrakt.park.origo.no:/etc/puppet/modules/nginx/templates/{nginx,vhost}.conf.erb #{ROOT}/lib/brow/templates/`
    `scp abstrakt.park.origo.no:/etc/puppet/modules/haproxy/templates/*.cfg.erb #{ROOT}/lib/brow/templates/`
    puts "Fetching mime.types"
    `scp abstrakt.park.origo.no:/etc/puppet/modules/nginx/files/mime.types #{ROOT}/lib/brow/templates/`    
    puts "Done"
  end
end
  
