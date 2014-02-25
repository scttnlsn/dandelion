require 'spec_helper'

describe Dandelion::Workspace do
  let!(:adapter) { Object.new }
  let!(:workspace) { Dandelion::Workspace.new(test_repo, adapter) }

  let!(:head_ref) { '3d9b743acb4a84dd99002d2c6f3fcf1a47e9f06b' }
  let!(:initial_ref) { 'e289ff1e2729839759dbd6fe99b6e35880910c7c' }

  describe '#local_commit' do
    context 'no ref specified' do
      it 'returns head commit' do
        expect(workspace.local_commit.oid).to eq head_ref
      end
    end

    context 'valid ref specified' do
      let!(:workspace) { Dandelion::Workspace.new(test_repo, adapter, ref: initial_ref) }

      it 'returns commit for given ref' do
        expect(workspace.local_commit.oid).to eq initial_ref
      end
    end

    context 'invalid ref specified' do
      let!(:workspace) { Dandelion::Workspace.new(test_repo, adapter, ref: 'abcdef' ) }

      it 'returns nil' do
        expect(workspace.local_commit).to eq nil
      end
    end
  end

  describe '#remote_commit' do
    before(:each) do
      adapter.stub(:read).with('.revision').and_return(initial_ref)
    end

    it 'returns commit for ref read from adapter' do
      expect(workspace.remote_commit.oid).to eq initial_ref
    end
  end

  describe '#diff' do
    before(:each) do
      adapter.stub(:read).with('.revision').and_return(initial_ref)
    end

    context 'with no changes' do
      let!(:workspace) { Dandelion::Workspace.new(test_repo, adapter, ref: initial_ref) }

      it 'returns empty diff' do
        expect(workspace.diff.empty?).to be
      end
    end

    context 'with changes' do
      it 'returns non-empty diff' do
        expect(workspace.diff.empty?).to_not be
      end
    end
  end
end