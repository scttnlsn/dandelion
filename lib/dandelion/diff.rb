require 'forwardable'

module Dandelion
  class Diff
    extend Forwardable
    include Enumerable

    def_delegator :@target, :empty?
    def_delegator :@target, :each

    attr_reader :from_commit, :to_commit

    def initialize(from_commit, to_commit)
      @from_commit = from_commit
      @to_commit = to_commit

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

    def each
      @deltas.each do |delta|
        if delta.deleted?
          yield Change.new(delta.old_file[:path], :delete)
        else
          yield Change.new(delta.new_file[:path], :write)
        end
      end
    end
  end

  class FullDiff
    def initialize(diff)
      @deltas = diff.patches.map(&:delta)
    end

    def empty?
      @deltas.empty?
    end

    def each
      @deltas.each do |delta|
        yield Change.new(delta.new_file[:path], :write)
      end
    end
  end
end