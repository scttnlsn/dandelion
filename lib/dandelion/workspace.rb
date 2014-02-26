module Dandelion
  class Workspace
    def initialize(repo, adapter, options = {})
      @repo = repo
      @adapter = adapter
      @options = options.merge(default_options)
    end

    def local_commit
      lookup(revision)
    end

    def remote_commit
      sha = remote_sha
      sha ? lookup(remote_sha) : nil
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

    def revision
      @options[:revision] || @repo.head.target
    end

    def lookup(val)
      begin
        @repo.lookup(val)
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