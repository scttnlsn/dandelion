module Dandelion
  module Command
    class Status < Command::Base
      command :status

      def self.parser(options)
        OptionParser.new do |opts|
          opts.banner = 'Usage: dandelion status'
        end
      end

      def execute!
      end
    end
  end
end