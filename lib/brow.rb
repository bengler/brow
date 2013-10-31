HOME = File.expand_path(File.dirname(__FILE__)+"/..")

require 'erb'
require 'fileutils'
require "brow/version"
require "brow/server_process"
require "brow/app_manager"
require "brow/proxy"
require "brow/gitignore"
require "brow/nginx_config"
require "brow/haproxy_config"
require "brow/server_config"
require "brow/wrangler"
require "brow/hostsfile"
require "brow/shell_environment"
require "brow/pebble_file"
require "brow/application"
require "brow/application/updator"
