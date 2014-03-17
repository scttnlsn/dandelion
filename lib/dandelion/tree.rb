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
        info = object[name]
        return nil unless info
        return nil unless info[:type]

        object = @repo.lookup(info[:oid])
        return nil unless object
      end

      object.read_raw.data
    end
  end
end