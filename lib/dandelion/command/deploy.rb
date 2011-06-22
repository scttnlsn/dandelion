module Dandelion
  module Command
    class Deploy < Command::Base
      command 'deploy'
  
      class << self
        def parser(options)
          OptionParser.new do |opts|
            opts.banner = 'Usage: deploy [options] <revision>'
      
            options[:force] = false
            opts.on('-f', '--force', 'Force deployment') do
              options[:force] = true
            end
          end
        end
      end
      
      def setup(args)
        @revision = args.shift || 'HEAD'
      end
  
      def execute
        begin
          @deployment = deployment(@revision)
        rescue Git::RevisionError
          log.fatal("Invalid revision: #{@revision}")
          exit 1
        end
        
        log.info("Remote revision:      #{@deployment.remote_revision || '---'}")
        log.info("Deploying revision:   #{@deployment.local_revision}")
        
        validate(@deployment)
        @deployment.deploy
        
        log.info("Deployment complete")
      end
    end
  end
end