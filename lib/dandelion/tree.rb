module Dandelion
  class Tree
    attr_reader :commit

    def initialize(repo, commit)
      @repo = repo
      @commit = commit
    end

    def data(path)
      object = @commit.tree

      path.split('/').each do |name|
        return nil unless object[name]
        object = @repo.lookup(object[name][:oid])
        return nil unless object
      end

      object.read_raw.data
    end
  end
end