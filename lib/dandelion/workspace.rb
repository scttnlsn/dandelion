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

    def diff
      Diff.new(remote_commit, local_commit)
    end

  private

    def default_options
      { revision_file: '.revision' }
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
  end
end