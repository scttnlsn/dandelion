require 'forwardable'

module Dandelion
  class Diff
    extend ::Forwardable

    def_delegator :@target, :empty?

    attr_reader :from, :to

    def initialize(from_commit, to_commit, options = {})
      @from = from_commit
      @to = to_commit
      @options = options

      if from_commit.nil?
        @target = FullDiff.new(to_commit.diff(nil))
      else
        @target = PartialDiff.new(from_commit.diff(to_commit))
      end
    end

    def changed
      transformed_paths(@target.changed)
    end

    def deleted
      transformed_paths(@target.deleted)
    end

  private

    def transformed_paths(paths)
      paths.select(&method(:applicable?)).map(&method(:trim_path))
    end

    def local_path
      @options[:local_path] || ''
    end

    def applicable?(path)
      path.start_with?(local_path)
    end

    def trim_path(path)
      return path unless applicable?(path)
      trimmed = path[local_path.length..-1]
      trimmed = trimmed[1..-1] if trimmed[0] == File::SEPARATOR
      trimmed
    end
  end

private

  class PartialDiff
    def initialize(diff)
      @deltas = diff.deltas
    end

    def empty?
      @deltas.empty?
    end

    def changed
      @deltas.select { |d| !d.deleted? }.map { |d| d.new_file[:path] }
    end

    def deleted
      @deltas.select { |d| d.deleted? }.map { |d| d.old_file[:path] }
    end
  end

  class FullDiff
    def initialize(diff)
      @deltas = diff.patches.map(&:delta)
    end

    def empty?
      @deltas.empty?
    end

    def changed
      @deltas.map { |delta| delta.new_file[:path] }
    end

    def deleted
      []
    end
  end
end