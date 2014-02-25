module Dandelion
  class Deployer
    def initialize(repo, adapter, options = {})
      @repo = repo
      @adapter = adapter
      @options = options
    end

    def deploy!(diff)
      diff.changed.reject(&method(:exclude?)).each do |path|
        @adapter.write(path, data(diff.to.tree, path))
      end

      diff.deleted.reject(&method(:exclude?)).each do |path|
        @adapter.delete(path)
      end
    end

  private

    def data(tree, path)
      object = tree

      path.split('/').each do |name|
        oid = object[name][:oid]
        object = @repo.lookup(oid)
      end

      object.read_raw.data
    end

    def exclude?(path)
      excluded = @options[:exclude] || []
      excluded.map { |e| path.start_with?(e) }.any?
    end
  end
end