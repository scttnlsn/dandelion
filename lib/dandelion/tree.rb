module Dandelion
  class Tree
    attr_reader :commit

    def initialize(repo, commit)
      @repo = repo
      @commit = commit
    end

    def data(path)
      object = @commit.tree
      info = {}

      path.split('/').each do |name|
        info = object[name]
        return nil unless info
        return nil unless info[:type]

        object = @repo.lookup(info[:oid])
        return nil unless object
      end

      # https://github.com/libgit2/libgit2/blob/development/include/git2/types.h
      if info[:filemode] == 0120000
        # Symlink
        path = object.read_raw.data
        data(path)
      else
        # Blob
        object.read_raw.data
      end
    end
  end
end