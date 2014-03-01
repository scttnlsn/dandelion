module Dandelion
  class Deployer
    def initialize(adapter, options = {})
      @adapter = adapter
      @options = options
    end

    def deploy_changeset!(changeset)
      changeset.each do |change|
        if exclude?(change.path)
          log.debug("Skipping file: #{change.path}")
        else
          case change.type
          when :write
            log.debug("Writing file:  #{change.path}")
            @adapter.write(change.path, change.data)
          when :delete
            log.debug("Deleting file: #{change.path}")  
            @adapter.delete(change.path)
          end
        end
      end
    end

    def deploy_files!(files)
      files.each do |path|
        local_path = remote_path = path

        if path.is_a?(Hash)
          local_path, remote_path = path.first
        end

        log.debug("Writing file:  #{local_path} -> #{remote_path}")
        @adapter.write(remote_path, IO.read(local_path))
      end
    end

  private

    def exclude?(path)
      excluded = @options[:exclude] || []
      excluded.map { |e| path.start_with?(e) }.any?
    end

    def log
      Dandelion.logger
    end
  end
end