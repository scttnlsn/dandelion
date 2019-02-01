module Dandelion
  class Tree
    # https://github.com/libgit2/libgit2/blob/development/include/git2/types.h
    FILEMODE_BLOB = 0100644
    FILEMODE_BLOB_EXECUTABLE = 0100755
    FILEMODE_SYMLINK = 0120000

    attr_reader :commit

    def initialize(repo, commit)
      @repo = repo
      @commit = commit
    end

    def symlink?(path)
      filemode(path) == FILEMODE_SYMLINK
    end

    def blob?(path)
      mode = filemode(path)
      mode == FILEMODE_BLOB || mode == FILEMODE_BLOB_EXECUTABLE
    end

    def data(path)
      if blob?(path) || symlink?(path)
        obj = object(path)
        blob_content(obj)
      else
        # TODO
        nil
      end
    end

    private

    def info(path)
      @commit.tree.path(path)
    end

    def filemode(path)
      info(path)[:filemode]
    end

    def object(path)
      oid = info(path)[:oid]
      @repo.lookup(oid)
    end

    def blob_content(object)
      object.read_raw.data
    end
  end
end
