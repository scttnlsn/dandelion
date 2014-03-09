require 'spec_helper'

describe Dandelion::Diff do
  let(:from_commit) { test_repo.lookup('e289ff1e2729839759dbd6fe99b6e35880910c7c') }
  let(:to_commit) { test_repo.lookup('3d9b743acb4a84dd99002d2c6f3fcf1a47e9f06b') }

  context 'non-nil from commit' do
    let(:diff) { test_diff }

    describe '#empty?' do
      it 'returns true if there are no changes' do
        expect(diff.empty?).to_not be
      end
    end

    describe '#enumerable' do
      it 'returns all changes between commits' do
        expect(diff.to_a.length).to eq 5
      end

      it 'returns write paths' do
        changes = diff.select { |c| c.type == :write }.map(&:path)

        expect(changes).to include 'foo'
        expect(changes).to include 'qux'
        expect(changes).to include 'baz/bar'
        expect(changes.length).to eq 3
      end

      it 'returns delete paths' do
        changes = diff.select { |c| c.type == :delete }.map(&:path)

        expect(changes).to include 'bar'
        expect(changes).to include 'baz/foo'
        expect(changes.length).to eq 2
      end
    end
  end

  context 'nil from commit' do
    let(:diff) { Dandelion::Diff.new(nil, to_commit) }

    describe '#enumerable' do
      it 'returns all paths in to commit' do
        changes = diff.map(&:path)

        expect(changes).to include 'foo'
        expect(changes).to include 'qux'
        expect(changes).to include 'baz/bar'
        expect(changes.length).to eq 3
      end
    end
  end
end