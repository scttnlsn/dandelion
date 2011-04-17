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
        return if dir == "."
        parent_dir = File.dirname(dir)
        file_names = @ftp.nlst(parent_dir)
        unless file_names.include? dir
          mkdir_p(parent_dir)
          @ftp.mkdir(dir)
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