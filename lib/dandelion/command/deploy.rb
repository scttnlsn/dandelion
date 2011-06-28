module Dandelion
  module Command
    class Deploy < Command::Base
      command 'deploy'
  
      class << self
        def parser(options)
          OptionParser.new do |opts|
            opts.banner = 'Usage: deploy [options] [<revision>]'
      
            options[:force] = false
            opts.on('-f', '--force', 'Force deployment') do
              options[:force] = true
            end
            
            options[:dry] = false
            opts.on('--dry-run', 'Show what would have been deployed') do
              options[:dry] = true
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
        
        begin
          @deployment.validate
        rescue Deployment::FastForwardError
          if !@options[:force]
            log.warn('Warning: you are trying to deploy unpushed commits')
            log.warn('This could potentially prevent others from being able to deploy')
            log.warn('If you are sure you want to this, use the -f option to force deployment')
            exit 1
          end
        end
        
        @deployment.deploy
        log.info("Deployment complete")
      end
    end
  end
end