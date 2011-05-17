require 'dandelion/backend'

module Dandelion
  module Backend
    class SFTP < Backend
      scheme 'sftp'
      gems 'net-sftp'
      
      def initialize(config)
        require 'net/sftp'
        @host = config['host']
        @username = config['username']
        @path = config['path']
        @sftp = Net::SFTP.start(@host, @username, :password => config['password'])
      end

      def read(file)
        begin
          @sftp.file.open(File.join(@path, file), 'r') do |f|
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
            path = File.join(@path, file)
            @sftp.upload!(temp, path)
          rescue Net::SFTP::StatusException => e
            raise unless e.code == 2
            mkdir_p(File.dirname(path))
            @sftp.upload!(temp, path)
          end
        end
      end

      def delete(file)
        begin
          path = File.join(@path, file)
          @sftp.remove!(path)
          cleanup(File.dirname(path))
        rescue Net::SFTP::StatusException => e
          raise unless e.code == 2
        end
      end
      
      def to_s
        "sftp://#{@username}@#{@host}/#{@path}"
      end

      private

      def cleanup(dir)
        unless File.expand_path(dir) == File.expand_path(@path)
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
    end
  end
end