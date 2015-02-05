module Dandelion
  class Changeset
    include Enumerable

    def initialize(tree, commit, options = {})
      @tree = tree
      @commit = commit
      @options = options
    end

    def diff
      Diff.new(@commit, @tree.commit)
    end

    def empty?
      diff.empty?
    end

    def each
      diff.each do |change|
        if applicable?(change.path)
          path = transform_path(change.path)

          if change.type == :delete
            yield Change.new(path, change.type)
          else
            read = -> { @tree.data(change.path) }
            yield Change.new(path, change.type, read)
          end
        end
      end
    end

  private

    def expand_path(path)
      File.expand_path(path).to_s
    end

    def local_path
      expand_path(@options[:local_path] || '')
    end

    def applicable?(path)
      expand_path(path).start_with?(expand_path(local_path))
    end

    def transform_path(path)
      trimmed = expand_path(path)[expand_path(local_path).length..-1]
      trimmed = trimmed[1..-1] if trimmed[0] == File::SEPARATOR
      trimmed
    end
  end
end
