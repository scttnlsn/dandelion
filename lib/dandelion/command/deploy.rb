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

      def deployer
        if options[:dry]
          noop_adapter = Adapter::NoOpAdapter.new(config)
          Deployer.new(repo, noop_adapter, config)
        else
          Deployer.new(repo, adapter, config)
        end
      end

      def setup(args)
        config[:revision] = args.shift || nil
      end

      def execute!
        log.info("Connecting to #{adapter.to_s}")

        diff = workspace.diff

        if diff.empty?
          log.info("No changes to deploy")
        else
          deployer.deploy!(workspace.diff)
          workspace.remote_commit = workspace.local_commit unless options[:dry]
        end
      end
    end
  end
end