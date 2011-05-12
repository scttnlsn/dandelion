require 'tempfile'

module Dandelion
  module Backend
    class MissingFileError < StandardError; end

    class Backend
      class << self
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