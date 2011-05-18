require 'dandelion/backend'
require 'pathname'

module Dandelion
  module Backend
    class SFTP < Backend
      scheme 'sftp'
      gems 'net-sftp'
      
      def initialize(config)
        require 'net/sftp'
        @config = config
        @sftp = Net::SFTP.start(@config['host'], @config['username'], :password => @config['password'])
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
            @sftp.upload! temp, path(file)
          rescue Net::SFTP::StatusException => e
            raise unless e.code == 2
            mkdir_p File.dirname(path(file))
            @sftp.upload! temp, path(file)
          end
        end
      end

      def delete(file)
        begin
          @sftp.remove! path(file)
          cleanup File.dirname(path(file))
        rescue Net::SFTP::StatusException => e
          raise unless e.code == 2
        end
      end
      
      def to_s
        "sftp://#{@config['username']}@#{@config['host']}/#{@config['path']}"
      end

      private
      
      def cleanpath(path)
        Pathname.new(path).cleanpath.to_path if path
      end

      def cleanup(dir)
        unless cleanpath(dir) == cleanpath(@path) or dir == File.dirname(dir)
          if empty? dir
            @sftp.rmdir! dir
            cleanup File.dirname(dir)
          end
        end
      end
      
      def empty?(dir)
        @sftp.dir.entries(dir).delete_if { |file| file.name == '.' or file.name == '..' }.empty?
      end

      def mkdir_p(dir)
        begin
          @sftp.mkdir! dir
        rescue Net::SFTP::StatusException => e
          raise unless e.code == 2
          mkdir_p File.dirname(dir)
          retry
        end
      end
      
      def path(file)
        if @config['path'] and !@config['path'].empty?
          File.join @config['path'], file
        else
          file
        end
      end
    end
  end
end