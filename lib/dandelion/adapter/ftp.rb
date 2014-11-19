require 'dandelion/utils'

module Dandelion
  module Adapter
    class FTP < Adapter::Base
      include ::Dandelion::Utils

      adapter 'ftp'

      def initialize(config)
        require 'net/ftp'

        @config = config
        @config.defaults(port: Net::FTP::FTP_PORT)
        @config[:passive] = to_b(@config[:passive])

        @ftp = ftp_client
      end

      def read(file)
        begin
          @ftp.getbinaryfile(path(file), nil)
        rescue Net::FTPPermError => e
          nil
        end
      end

      def write(file, data)
        temp(file, data) do |temp|
          begin
            @ftp.putbinaryfile(temp, path(file))
          rescue Net::FTPPermError => e
            raise e unless e.to_s =~ /550|553/
            mkdir_p(File.dirname(path(file)))
            @ftp.putbinaryfile(temp, path(file))
          end
        end
      end

      def delete(file)
        begin
          @ftp.delete(path(file))
          cleanup(File.dirname(path(file)))
        rescue Net::FTPPermError => e
        end
      end

      def to_s
        "ftp://#{@config['username']}@#{@config['host']}/#{@config['path']}"
      end

    private

      def ftp_client
        ftp = Net::FTP.new
        ftp.connect(@config['host'], @config['port'])
        ftp.login(@config['username'], @config['password'])
        ftp.passive = @config['passive']
        ftp
      end

      def cleanup(dir)
        unless dir == File.dirname(dir)
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
        unless dir == File.dirname(dir)
          begin
            @ftp.mkdir(dir)
          rescue Net::FTPPermError => e
            mkdir_p(File.dirname(dir))
            @ftp.mkdir(dir)
          end
        end
      end

      def path(file)
        if @config['path'] and !@config['path'].empty?
          File.join(@config['path'], file)
        else
          file
        end
      end

      def to_b(value)
        return [true, 'true', 1, '1', 'T', 't'].include?(value.class == String ? value.downcase : value)
      end
    end
  end
end
