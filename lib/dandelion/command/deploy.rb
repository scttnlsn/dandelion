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
          noop_adapter = Adapter::NoOpAdapter.new
          Deployer.new(repo, noop_adapter, config)
        else
          Deployer.new(repo, adapter, config)
        end
      end

      def execute!
        deployer.deploy!(workspace.diff)
      end
    end
  end
end