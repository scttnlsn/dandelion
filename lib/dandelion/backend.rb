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
          elsif config['scheme'] == 'ftp'
            require 'dandelion/backend/ftp'
            klass = FTP
          elsif config['scheme'] == 's3'
            require 'dandelion/backend/s3'
            klass = S3
          else
            raise UnsupportedSchemeError
          end
          begin
            klass.new(config)
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