module Dandelion
  class Deployer
    def initialize(adapter, options = {})
      @adapter = adapter
      @options = options
    end

    def deploy!(changeset)
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