module Dandelion
  class Workspace
    def initialize(repo, adapter, options = {})
      @repo = repo
      @adapter = adapter
      @options = options.merge(default_options)
    end

    def local_commit
      lookup(ref)
    end

    def remote_commit
      lookup(remote_sha)
    end

    def remote_commit=(commit)
      self.remote_sha = commit.oid
    end

    def diff
      Diff.new(remote_commit, local_commit, local_path: @options[:local_path])
    end

  private

    def default_options
      { revision_file: '.revision', local_path: '' }
    end

    def ref
      @options[:ref] || @repo.head.target
    end

    def lookup(ref)
      begin
        @repo.lookup(ref)
      rescue Rugged::OdbError
        nil
      end
    end

    def remote_sha
      @adapter.read(@options[:revision_file])
    end

    def remote_sha=(sha)
      @adapter.write(@options[:revision_file], sha)
    end
  end
end