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
        @@backends = {}
        
        def create(config)
          Dir.glob(File.join(File.dirname(__FILE__), 'backend', '*.rb')) { |file| require file }
          raise UnsupportedSchemeError unless @@backends.include? config['scheme']
          begin
            @@backends[config['scheme']].new(config)
          rescue LoadError
            raise MissingDependencyError.new(@@backends[config['scheme']].gem_list)
          end
        end
        
        def scheme(scheme)
          @@backends[scheme] = self
        end
        
        def gems(*gems)
          @gems = gems
        end
        
        def gem_list
          @gems
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