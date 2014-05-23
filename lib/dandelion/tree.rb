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

      content(info, object)
    end

  private

    def content(info, object)
      # https://github.com/libgit2/libgit2/blob/development/include/git2/types.h
      if info[:filemode] == 0120000
        symlink_content(object)
      else
        blob_content(object)
      end
    end

    def blob_content(object)
      object.read_raw.data
    end

    def symlink_content(object)
      path = object.read_raw.data

      result = data(path)
      result ||= IO.binread(path) # external link
      result
    end
  end
end