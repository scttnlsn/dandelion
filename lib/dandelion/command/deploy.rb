module Dandelion
  module Command
    class Deploy < Command::Base
      command :deploy

      def self.parser(options)
        OptionParser.new do |opts|
          opts.banner = 'Usage: dandelion deploy [options] [<revision>]'

          options[:dry] = false
          opts.on('--dry-run', 'Show what would have been deployed') do
            options[:dry] = true
          end
        end
      end

      def setup(args)
        config[:revision] = args.shift || nil
      end

      def execute!
        log.info("Connecting to #{adapter.to_s}")

        local_commit = workspace.local_commit
        remote_commit = workspace.remote_commit
        
        log.info("Remote revision:    #{remote_commit ? remote_commit.oid : '---'}")
        log.info("Deploying revision: #{local_commit.oid}")

        changeset = workspace.changeset

        if changeset.empty?
          log.info("No changes to deploy")
        else
          deployer.deploy!(workspace.changeset)
          workspace.remote_commit = workspace.local_commit unless options[:dry]
        end
      end

      def deployer_adapter
        if options[:dry]
          Adapter::NoOpAdapter.new(config)
        else
          adapter
        end
      end

      def deployer
        Deployer.new(deployer_adapter, config)
      end
    end
  end
end