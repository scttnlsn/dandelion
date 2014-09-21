module Dandelion
  module Adapter
    class InvalidAdapterError < StandardError; end

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
          raise InvalidAdapterError if klass.nil?
          klass.new(options)
        rescue LoadError
          raise MissingDependencyError.new(klass.required_gems)
        end

        attr_reader :required_gems

        def requires_gems(*gems)
          @required_gems = gems
        end
      end

      def initialize(options)
      end
    end
  end
end

require 'dandelion/adapter/noop'
require 'dandelion/adapter/ftp'
require 'dandelion/adapter/sftp'
require 'dandelion/adapter/ftps'
require 'dandelion/adapter/s3'