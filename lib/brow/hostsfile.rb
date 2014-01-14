require 'ghost'

module Brow
  module HostsFile

    DOMAIN_SUFFIX = 'dev'

    # Remove mappings from /etc/hosts.
    def self.remove_all
      update([])
    end

    # Adds mappings to /etc/hosts.
    def self.update(application_names)
      store = Ghost.store
      store.all.each do |host|
        # Delete old names we have previously added
        if host.name.end_with(".#{DOMAIN_SUFFIX}")
          store.delete(host)
        end
      end
      application_names.each do |name|
        store.add(
          Ghost::Host.new("#{name}.#{DOMAIN_SUFFIX}", '127.0.0.1'))
      end

      if `which dscacheutil` != ''
        system('dscacheutil -flushcache')
      end

      if `which nscd` != ''
        system('sudo service nscd restart')
      end
    end

  end
end