require "bundler/gem_tasks"

ROOT = File.dirname(__FILE__)

namespace :config do
  desc "fetch Fetch most recent config info from production environment"
  task :sync do
    puts "Fetching templates"
    `scp abstrakt.park.origo.no:/etc/puppet/modules/ruby/templates/{site,unicorn}.rb.erb #{ROOT}/lib/brow/templates/`
    puts "Done"
  end
end
  
