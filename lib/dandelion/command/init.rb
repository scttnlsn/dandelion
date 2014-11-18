module Dandelion
  module Command
    class Init < Command::Base
      command :init

      def self.parser(options)
        OptionParser.new do |opts|
          opts.banner = 'Usage: dandelion init <revision>'
        end
      end

      def setup(args)
        @revision = args.shift
      end

      def execute!
        raise RevisionError.new('must specify revision') if @revision.nil?
        log.info("Connecting to #{adapter.to_s}")

        workspace.remote_commit = workspace.lookup(@revision)
        remote_commit = workspace.remote_commit

        log.info("Remote revision:      #{remote_commit ? remote_commit.oid : '---'}")
        log.info("Local HEAD revision:  #{workspace.local_commit.oid}")
      end
    end
  end
end
