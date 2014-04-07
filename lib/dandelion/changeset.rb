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

    def local_path
      @options[:local_path] || ''
    end

    def applicable?(path)
      path.start_with?(local_path)
    end

    def transform_path(path)
      trimmed = path[local_path.length..-1]
      trimmed = trimmed[1..-1] if trimmed[0] == File::SEPARATOR
      trimmed
    end
  end
end