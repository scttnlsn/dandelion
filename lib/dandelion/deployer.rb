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
          deploy_change!(change)
        end
      end
    end

    def deploy_files!(files)
      files.each do |path|
        local_path = remote_path = path

        if path.is_a?(Hash)
          local_path, remote_path = path.first
        end

        if File.directory?(local_path)
          paths = expand_paths(local_path, remote_path)
        else
          paths = [[local_path, remote_path]]
        end

        paths.each do |local_path, remote_path|
          deploy_file!(local_path, remote_path)
        end
      end
    end

  private

    def deploy_file!(local_path, remote_path)
      log.debug("Writing file:  #{local_path} -> #{remote_path}")
      @adapter.write(remote_path, IO.binread(local_path))
    end

    def deploy_change!(change)
      case change.type
      when :write
        log.debug("Writing file:  #{change.path}")
        @adapter.write(change.path, change.data)
      when :delete
        log.debug("Deleting file: #{change.path}")  
        @adapter.delete(change.path)
      end
    end

    def exclude?(path)
      excluded = @options[:exclude] || []
      excluded.map { |e| path.start_with?(e) }.any?
    end

    def expand_paths(dir, remote_path)
      paths = Dir.glob(File.join(dir, '**/*')).map do |path|
        trimmed = trim_path(dir, path)
        [path, File.join(remote_path, trimmed)]
      end

      paths.reject do |local_path, remote_path|
        File.directory?(local_path)
      end
    end

    def trim_path(dir, path)
      path[dir.length..-1]
    end

    def log
      Dandelion.logger
    end
  end
end