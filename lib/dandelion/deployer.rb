module Dandelion
  class Deployer
    def initialize(repo, adapter)
      @repo = repo
      @adapter = adapter
    end

    def deploy!(diff)
      diff.changed.each do |path|
        @adapter.write(path, data(diff.to.tree, path))
      end

      diff.deleted.each do |path|
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
  end
end