module Dandelion
  module Adapter
    class MissingDependencyError < StandardError
      attr_reader :gems

      def initialize(gems)
        @gems = gems
      end
    end

    class Base
      class << self
        @@adapters = {}

        def adapter(name)
          @@adapters[name] = self
        end

        def create_adapter(name, options = {})
          klass = @@adapters[name]
          return nil if klass.nil?

          begin
            klass.new(options)
          rescue LoadError
            raise MissingDependencyError.new(klass.required_gems)
          end
        end

        attr_reader :required_gems

        def requires_gems(*gems)
          @required_gems = gems
        end
      end

      def initialize(config)
      end
    end
  end
end

require 'dandelion/adapter/noop'
require 'dandelion/adapter/s3'