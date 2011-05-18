require 'dandelion/backend'

module Dandelion
  module Backend
    class FTP < Backend
      scheme 'ftp'
      
      def initialize(config)
        require 'net/ftp'
        @config = config
        @ftp = Net::FTP.open(@config['host'], @config['username'], @config['password'])
        @ftp.passive = true
        @ftp.chdir(config['path'])
      end

      def read(file)
        begin
          # Implementation of FTP#getbinaryfile differs between 1.8
          # and 1.9 so we call FTP#retrbinary directly
          content = ''
          @ftp.retrbinary("RETR #{file}", 4096) do |data|
            content += data
          end
          content
        rescue Net::FTPPermError => e
          raise MissingFileError
        end
      end

      def write(file, data)
        temp(file, data) do |temp|
          begin
            @ftp.putbinaryfile temp, file
          rescue Net::FTPPermError => e
            mkdir_p File.dirname(file)
            @ftp.putbinaryfile temp, file
          end
        end
      end

      def delete(file)
        begin
          @ftp.delete file
          cleanup File.dirname(file)
        rescue Net::FTPPermError => e
        end
      end
      
      def to_s
        "ftp://#{@config['username']}@#{@config['host']}/#{@config['path']}"
      end

      private

      def cleanup(dir)
        unless dir == File.dirname(dir)
          if empty? dir
            @ftp.rmdir dir
            cleanup File.dirname(dir)
          end
        end
      end

      def empty?(dir)
        return @ftp.nlst(dir).empty?
      end

      def mkdir_p(dir)
        unless dir == File.dirname(dir)
          begin
            @ftp.mkdir dir
          rescue Net::FTPPermError => e
            mkdir_p File.dirname(dir)
            @ftp.mkdir dir
          end
        end
      end
    end
  end
end