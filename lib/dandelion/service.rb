require 'net/ftp'
require 'net/sftp'
require 'tempfile'

module Dandelion
  module Service
    class MissingFileError < StandardError; end

    class Service
      def initialize(host, username, path)
        @host = host
        @username = username
        @path = path
      end

      def uri
        "#{@scheme}://#{@username}@#{@host}/#{@path}"
      end

      protected

      def temp(file, data)
        tmp = Tempfile.new(file.gsub('/', '.'))
        tmp << data
        tmp.flush
        yield(tmp.path)
        tmp.close
      end
    end

    class FTP < Service
      def initialize(host, username, password, path)
        super(host, username, path)
        @scheme = 'ftp'
        @ftp = Net::FTP.open(host, username, password)
        @ftp.passive = true
        @ftp.chdir(path)
      end

      def read(file)
        begin
          content = ''
          @ftp.getbinaryfile(file) do |data|
            content += data
          end
          content
        rescue Net::FTPPermError => e
          raise MissingFileError
        end
      end

      def write(file, data)
        begin
          dir = File.dirname(file)
          @ftp.list(dir)
        rescue Net::FTPTempError => e
          mkdir_p(dir)
        end
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

      private

      def cleanup(dir)
        unless File.identical?(dir, @path)
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
        begin
          @ftp.mkdir(dir)
        rescue Net::FTPPermError => e
          mkdir_p(File.dirname(dir))
          mkdir_p(dir)
        end
      end
    end

    class SFTP < Service
      def initialize(host, username, password, path)
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