require 'tempfile'

module Dandelion
  module Backend
    class MissingFileError < StandardError; end
    class UnsupportedSchemeError < StandardError; end
    
    class MissingDependencyError < StandardError
      attr_reader :gems
      
      def initialize(gems)
        @gems = gems
      end
    end

    class Backend
      class << self
        def create(config)
          if config['scheme'] == 'sftp'
            require 'dandelion/backend/sftp'
            klass = SFTP
            args = [config['host'], config['username'], config['password'], config['path']]
          elsif config['scheme'] == 'ftp'
            require 'dandelion/backend/ftp'
            klass = FTP
            args = [config['host'], config['username'], config['password'], config['path']]
          elsif config['scheme'] == 's3'
            require 'dandelion/backend/s3'
            klass = S3
            args = [config['access_key_id'], config['secret_access_key'], config['bucket'], config['path']]
          else
            raise UnsupportedSchemeError
          end
          begin
            klass.new(*args)
          rescue LoadError
            raise MissingDependencyError.new(klass.gems)
          end
        end
        
        def gems
          []
        end
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
  end
end