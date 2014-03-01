module Dandelion
  class RevisionError < StandardError; end

  class Workspace
    attr_reader :adapter
    
    def initialize(repo, adapter, config = {})
      @repo = repo
      @adapter = adapter
      @config = config.merge(default_options)
    end

    def tree
      Tree.new(@repo, local_commit)
    end

    def changeset
      Changeset.new(tree, remote_commit)
    end

    def local_commit
      lookup(local_sha)
    end

    def remote_commit
      sha = remote_sha
      sha ? lookup(remote_sha) : nil
    end

    def remote_commit=(commit)
      self.remote_sha = commit.oid
    end

  private

    def default_options
      { revision_file: '.revision', local_path: '' }
    end

    def lookup(val)
      begin
        begin
          if ref = @repo.ref(val)
            val = ref.target.to_s
          end
        rescue Rugged::ReferenceError
        end

        @repo.lookup(val)
      rescue Rugged::OdbError, Rugged::InvalidError
        raise RevisionError.new(val)
      end
    end

    def local_sha
      @config[:revision] || @repo.head.target
    end

    def remote_sha
      @remote_sha ||= @adapter.read(@config[:revision_file])
    end

    def remote_sha=(sha)
      @adapter.write(@config[:revision_file], sha)
      @remote_sha = sha
    end
  end
end