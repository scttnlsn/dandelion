require 'dandelion/backend'
require 'pathname'

module Dandelion
  module Backend
    class SFTP < Backend::Base
      scheme 'sftp'
      gems 'net-sftp'
      
      def initialize(config)
        require 'net/sftp'
        @config = { 'preserve_permissions' => true }.merge(config)
        options = {
          :password => @config['password'],
          :port => @config['port'] || Net::SSH::Transport::Session::DEFAULT_PORT,
        }
        @sftp = Net::SFTP.start(@config['host'], @config['username'], options)
      end

      def read(file)
        begin
          @sftp.file.open(path(file), 'r') do |f|
            f.gets
          end
        rescue Net::SFTP::StatusException => e
          raise unless e.code == 2
          raise MissingFileError
        end
      end

      def write(file, data)
        temp(file, data) do |temp|
          begin
            @sftp.upload!(temp, path(file))
          rescue Net::SFTP::StatusException => e
            raise unless e.code == 2
            mkdir_p(File.dirname(path(file)))
            @sftp.upload!(temp, path(file))
          end
        end
        if @config['preserve_permissions']
          mode = get_mode(file)
          @sftp.setstat!(path(file), :permissions => mode) if mode
        end
      end

      def delete(file)
        begin
          @sftp.remove!(path(file))
          cleanup(File.dirname(path(file)))
        rescue Net::SFTP::StatusException => e
          raise unless e.code == 2
        end
      end
      
      def to_s
        "sftp://#{@config['username']}@#{@config['host']}/#{@config['path']}"
      end

      private

      def get_mode(file)
        stat = File.stat(file) if File.exists?(file)
        stat.mode if stat
      end

      def cleanpath(path)
        Pathname.new(path).cleanpath.to_s if path
      end

      def cleanup(dir)
        unless cleanpath(dir) == cleanpath(@config['path']) or dir == File.dirname(dir)
          if empty?(dir)
            @sftp.rmdir!(dir)
            cleanup(File.dirname(dir))
          end
        end
      end
      
      def empty?(dir)
        @sftp.dir.entries(dir).delete_if { |file| file.name == '.' or file.name == '..' }.empty?
      end

      def mkdir_p(dir)
        begin
          @sftp.mkdir!(dir)
        rescue Net::SFTP::StatusException => e
          raise unless e.code == 2
          mkdir_p(File.dirname(dir))
          @sftp.mkdir!(dir)
        end
      end
      
      def path(file)
        if @config['path'] and !@config['path'].empty?
          File.join(@config['path'], file)
        else
          file
        end
      end
    end
  end
end
