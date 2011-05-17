module Dandelion
  module Backend
    class FTP < Backend
      scheme 'ftp'
      
      def initialize(config)
        require 'net/ftp'
        @host = config['host']
        @username = config['username']
        @path = config['path']
        @ftp = Net::FTP.open(@host, @username, config['password'])
        @ftp.passive = true
        @ftp.chdir(@path)
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
        # Creates directory only if necessary
        mkdir_p(File.dirname(file))

        temp(file, data) do |temp|
          @ftp.putbinaryfile(temp, file)
        end
      end

      def delete(file)
        begin
          @ftp.delete(file)
          cleanup(File.dirname(file))
        rescue Net::FTPPermError => e
        end
      end
      
      def to_s
        "ftp://#{@username}@#{@host}/#{@path}"
      end

      private

      def cleanup(dir)
        unless dir == '.'
          if empty?(dir)
            @ftp.rmdir(dir)
            cleanup(File.dirname(dir))
          end
        end
      end

      def empty?(dir)
        return @ftp.nlst(dir).empty?
      end

      def mkdir_p(dir)
        unless dir == '.'
          parent = File.dirname(dir)
          unless @ftp.nlst(parent).include? dir
            mkdir_p(parent)
            @ftp.mkdir(dir)
          end
        end
      end
    end
  end
end