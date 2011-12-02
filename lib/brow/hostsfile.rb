# Adds localhost-mappings to /etc/hosts

module Brow::HostsFile
  def self.update(application_names, domain = 'dev')
    service_lines = application_names.map do |name|
      "127.0.0.1\t#{name}.#{domain}\t#brow"
    end
    hosts_file_path = "/etc/hosts"
    hosts_file = File.read("/etc/hosts").split("\n").delete_if {|row| row =~ /.+(#brow)/}
    first_loopback_index = hosts_file.index {|i| i =~ /^(127.0.0.1).+/}
    hosts_file = hosts_file.insert(first_loopback_index + 1, service_lines)
    File.open("#{ENV['HOME']}/hosts-brow", "w")  do
      |file| file.puts hosts_file.join("\n")
    end
    %x{cp #{hosts_file_path} #{ENV['HOME']}/hosts-powder.bak}
    %x{sudo mv #{ENV['HOME']}/hosts-brow #{hosts_file_path}}
    %x{dscacheutil -flushcache}
  end
end