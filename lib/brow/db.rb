module Brow
  class DB

    attr_reader :name, :host, :backup_server
    def initialize(options)
      @name = options[:name]
      @host = options[:host]
      @backup_server = options[:backup_server]
    end

    def remote_path
      "#{host}:/var/backups/#{backup_server}/postgresql/#{name}_production/#{name}_production-latest.dump"
    end

    def local_path
     "/tmp/#{name}-latest.dump"
    end

    def db
      "#{name}_development"
    end

    def import
      system "scp #{remote_path} #{local_path}"
      system "dropdb #{db}"
      system "createdb -O #{name} #{db}"
      system "cat #{local_path} | pg_restore -Fc -d #{db}"
    end
  end
end
