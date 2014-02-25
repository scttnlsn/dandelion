require 'forwardable'

module Dandelion
  class Diff
    extend ::Forwardable

    def_delegator :@target, :empty?
    def_delegator :@target, :changed
    def_delegator :@target, :deleted

    attr_reader :from, :to

    def initialize(from_commit, to_commit)
      @from = from_commit
      @to = to_commit

      if from_commit.nil?
        @target = FullDiff.new(to_commit.diff(nil))
      else
        @target = PartialDiff.new(from_commit.diff(to_commit))
      end
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