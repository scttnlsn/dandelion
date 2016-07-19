module Dandelion
  class Tree
    attr_reader :commit

    def initialize(repo, commit)
      @repo = repo
      @commit = commit
    end

    def is_symlink?(path)
      # https://github.com/libgit2/libgit2/blob/development/include/git2/types.h
      @commit.tree.path(path)[:filemode] == 0120000
    end

    def data(path)
      submodule = @repo.submodules[path]

      if submodule
        # TODO
        nil
      else
        info, obj = object(path)
        blob_content(obj)
      end
    end

    private

    def object(path)
      info = @commit.tree.path(path)
      object = @repo.lookup(info[:oid])
      [info, object]
    end

    def blob_content(object)
      object.read_raw.data
    end

  end
end
