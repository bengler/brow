# Adds localhost-mappings to /etc/hosts

module Brow::HostsFile

  def self.hosts_file_path
    '/etc/hosts'
  end

  def self.update(application_names, domain = 'dev')
    service_lines = application_names.map do |name|
      "127.0.0.1\t#{name}.#{domain}\t#brow"
    end

    unless File.exists?(hosts_file_path)
      %x{sudo touch #{hosts_file_path}}
    end

    hosts_file = File.read("/etc/hosts").split("\n").delete_if {|row| row =~ /.+(#brow)/}
    hosts_file << "127.0.0.1\tlocalhost" if hosts_file.empty?
    first_loopback_index = hosts_file.index {|i| i =~ /^(127.0.0.1).+/}
    hosts_file = hosts_file.insert(first_loopback_index + 1, service_lines)
    File.open("#{ENV['HOME']}/hosts-brow", "w")  do
      |file| file.puts hosts_file.join("\n")
    end
    %x{cp #{hosts_file_path} #{ENV['HOME']}/hosts.bak}
    %x{sudo mv #{ENV['HOME']}/hosts-brow #{hosts_file_path}}
    if %x{uname} =~ /^Darwin/
      %x{dscacheutil -flushcache}
    else
      if %x{which nscd} =~ /nscd/
        %x{sudo service nscd restart}
      end
    end
  end
end
