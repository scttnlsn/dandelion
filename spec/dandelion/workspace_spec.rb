require 'spec_helper'

describe Dandelion::Workspace do
  let!(:adapter) { double('adapter') }
  let!(:workspace) { Dandelion::Workspace.new(test_repo, adapter) }

  let!(:head_revision) { '3d9b743acb4a84dd99002d2c6f3fcf1a47e9f06b' }
  let!(:initial_revision) { 'e289ff1e2729839759dbd6fe99b6e35880910c7c' }

  describe '#local_commit' do
    context 'no revision specified' do
      it 'returns head commit' do
        expect(workspace.local_commit.oid).to eq head_revision
      end
    end

    context 'valid revision specified' do
      let!(:workspace) { Dandelion::Workspace.new(test_repo, adapter, revision: initial_revision) }

      it 'returns commit for given revision' do
        expect(workspace.local_commit.oid).to eq initial_revision
      end
    end

    context 'invalid revision specified' do
      let!(:workspace) { Dandelion::Workspace.new(test_repo, adapter, revision: 'abcdef' ) }

      it 'returns nil' do
        expect(workspace.local_commit).to eq nil
      end
    end
  end

  describe '#remote_commit' do
    before(:each) do
      adapter.stub(:read).with('.revision').and_return(initial_revision)
    end

    it 'returns commit for revision read from adapter' do
      expect(workspace.remote_commit.oid).to eq initial_revision
    end
  end

  describe '#remote_commit=' do
    it 'writes commit revision to adapter' do
      adapter.should_receive(:write).with('.revision', head_revision)
      workspace.remote_commit = workspace.local_commit
    end
  end

  describe '#diff' do
    before(:each) do
      adapter.stub(:read).with('.revision').and_return(initial_revision)
    end

    context 'with no changes' do
      let!(:workspace) { Dandelion::Workspace.new(test_repo, adapter, revision: initial_revision) }

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