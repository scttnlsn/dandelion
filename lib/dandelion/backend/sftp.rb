module Dandelion
  module Backend
    class SFTP < Backend
      class << self
        def gems
          ['net-sftp']
        end
      end
      
      def initialize(host, username, password, path)
        require 'net/sftp'
        super(host, username, path)
        @scheme = 'sftp'
        @sftp = Net::SFTP.start(host, username, :password => password)
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
        path = File.join(@path, file)
        begin
          dir = File.dirname(path)
          @sftp.stat!(dir)
        rescue Net::SFTP::StatusException => e
          raise unless e.code == 2
          mkdir_p(dir)
        end
        temp(file, data) do |temp|
          @sftp.upload!(temp, path)
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

      private

      def cleanup(dir)
        unless File.identical?(dir, @path)
          if empty?(dir)
            @sftp.rmdir!(dir)
            cleanup(File.dirname(dir))
          end
        end
      end

      def empty?(dir)
        @sftp.dir.entries(dir).map do |entry|
          entry.name unless entry.name == '.' or entry.name == '..'
        end.compact.empty?
      end

      def mkdir_p(dir)
        begin
          @sftp.mkdir!(dir)
        rescue Net::SFTP::StatusException => e
          raise unless e.code == 2
          mkdir_p(File.dirname(dir))
          mkdir_p(dir)
        end
      end
    end
  end
end