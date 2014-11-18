module Dandelion
  class RevisionError < StandardError; end

  class Workspace
    attr_reader :adapter, :config

    def initialize(repo, adapter, config = nil)
      @repo = repo
      @adapter = adapter

      if config.is_a?(Hash)
        @config = Config.new(data: config)
      else
        @config = config || Config.new
      end

      @config.defaults(revision_file: '.revision', local_path: '')
    end

    def tree
      Tree.new(@repo, local_commit)
    end

    def changeset
      Changeset.new(tree, remote_commit, @config)
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

    def lookup(val)
      result = lookup_sha(val) ||
        lookup_ref(val) ||
        lookup_ref("refs/tags/#{val}") ||
        lookup_ref("refs/branches/#{val}") ||
        lookup_ref("refs/heads/#{val}")

      raise RevisionError.new(val) unless result

      result
    end

  private

    def lookup_sha(val)
      @repo.lookup(val)
    rescue Rugged::OdbError, Rugged::InvalidError
      nil
    end

    def lookup_ref(val)
      ref = @repo.ref(val)
      lookup_sha(ref.target.oid) if ref
    rescue Rugged::ReferenceError
      nil
    end

    def local_sha
      @config[:revision] || @repo.head.target.oid
    end

    def remote_sha
      @remote_sha ||= begin
        sha = @adapter.read(@config[:revision_file])
        sha.chomp if sha
      end
    end

    def remote_sha=(sha)
      @adapter.write(@config[:revision_file], sha)
      @remote_sha = sha
    end
  end
end
