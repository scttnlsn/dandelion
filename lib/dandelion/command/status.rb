module Dandelion
  module Command
    class Status < Command::Base
      command 'status'
  
      class << self
        def parser(options)
          OptionParser.new do |opts|
            opts.banner = 'Usage: dandelion status'
          end
        end
      end
  
      def execute
        @deployment = deployment('HEAD')
        
        log.info("Remote revision:       #{@deployment.remote_revision || '---'}")
        log.info("Local HEAD revision:   #{@deployment.local_revision}")
      end
    end
  end
end