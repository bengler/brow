HOME = File.expand_path(File.dirname(__FILE__)+"/..")

require 'erb'
require "brow/version"
require "brow/server_process"
require "brow/app_manager"
require "brow/proxy"
require "brow/nginx_config"
require "brow/unicorn_config"
require "brow/wrangler"
require "brow/hostsfile"
require "brow/shell_environment"
require "brow/watcher"
require "brow/application"