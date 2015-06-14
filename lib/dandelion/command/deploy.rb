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

        deploy_changeset!
        deploy_additional_files!

        cloudfront_invalidate! unless !@config[:cloudfront] or !@config[:cloudfront]["invalidate"] or !@config[:cloudfront]["distribution"]
      end

      def deployer_adapter
        if options[:dry]
          Adapter::NoOpAdapter.new(config)
        else
          adapter
        end
      end

      def deployer
        @deployer ||= Deployer.new(deployer_adapter, config)
      end

    private

      def deploy_changeset!
        changeset = workspace.changeset

        if changeset.empty?
          log.info("No changes to deploy")
        else
          log.info("Deploying changes...")
          deployer.deploy_changeset!(workspace.changeset)
          workspace.remote_commit = workspace.local_commit unless options[:dry]
        end
      end

      def deploy_additional_files!
        if config[:additional] && config[:additional].length > 0
          log.info("Deploying additional files...")
          deployer.deploy_files!(config[:additional])
        end
      end

      #
      # Cloudfront cache invalidation
      def cloudfront_invalidate!
        require "cloudfront-invalidator"

        # Fetch files from config or use wildcard, if none given
        files = if @config[:cloudfront]["files"] then @config[:cloudfront]["files"] else '*' end

        log.info("Invalidating Amazon Cloudfront...")
        CloudfrontInvalidator.new(@config[:access_key_id], @config[:secret_access_key], @config[:cloudfront]["distribution"]).invalidate(files) unless options[:dry]
        log.info("Invalidation in progress. Check your AWS console for more information.")
      end
    end
  end
end