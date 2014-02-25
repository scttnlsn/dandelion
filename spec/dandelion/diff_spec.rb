require 'spec_helper'

describe Dandelion::Diff do
  let(:from_commit) { test_repo.lookup('e289ff1e2729839759dbd6fe99b6e35880910c7c') }
  let(:to_commit) { test_repo.lookup('3d9b743acb4a84dd99002d2c6f3fcf1a47e9f06b') }

  context 'non-nil from commit' do
    let(:diff) { Dandelion::Diff.new(from_commit, to_commit) }

    describe '#empty?' do
      it 'returns true if there are no changes or deletes' do
        expect(diff.empty?).to_not be
      end
    end

    describe '#changed' do
      it 'returns paths that have changed between commits' do
        expect(diff.changed).to include 'foo'
        expect(diff.changed).to include 'qux'
        expect(diff.changed).to include 'baz/bar'
        expect(diff.changed.length).to eq 3
      end
    end

    describe '#deleted' do
      it 'returns paths that have been deleted between commits' do
        expect(diff.deleted).to include 'bar'
        expect(diff.deleted).to include 'baz/foo'
        expect(diff.deleted.length).to eq 2
      end

      it 'does not include paths that were added and deleted' do
        expect(diff.deleted).to_not include 'baz/qux'
      end
    end
  end

  context 'nil from commit' do
    let(:diff) { Dandelion::Diff.new(nil, to_commit) }

    describe '#changed' do
      it 'returns all paths in to commit' do
        expect(diff.changed).to include 'foo'
        expect(diff.changed).to include 'qux'
        expect(diff.changed).to include 'baz/bar'
        expect(diff.changed.length).to eq 3
      end
    end
  end
end