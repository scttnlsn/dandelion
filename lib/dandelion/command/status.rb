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
        log.info("Connecting to #{adapter.to_s}")

        local_commit = workspace.local_commit
        remote_commit = workspace.remote_commit

        log.info("Remote revision:      #{remote_commit ? remote_commit.oid : '---'}")
        log.info("Local HEAD revision:  #{workspace.local_commit.oid}")
      end
    end
  end
end