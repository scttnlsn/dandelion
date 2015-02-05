require 'spec_helper'

describe Dandelion::Workspace do
  let(:adapter) { double('adapter') }
  let(:workspace) { Dandelion::Workspace.new(test_repo, adapter) }

  let(:head_revision) { '3d9b743acb4a84dd99002d2c6f3fcf1a47e9f06b' }
  let(:initial_revision) { 'e289ff1e2729839759dbd6fe99b6e35880910c7c' }

  it 'has an adapter' do
    expect(workspace.adapter).to eq adapter
  end

  describe '#local_commit' do
    context 'no revision specified' do
      it 'returns head commit' do
        expect(workspace.local_commit.oid).to eq head_revision
      end
    end

    context 'valid revision specified' do
      context 'sha' do
        let(:workspace) { Dandelion::Workspace.new(test_repo, adapter, revision: initial_revision) }

        it 'returns commit for given revision' do
          expect(workspace.local_commit.oid).to eq initial_revision
        end
      end

      context 'tag' do
        let(:workspace) { Dandelion::Workspace.new(test_repo, adapter, revision: 'test-tag') }

        it 'returns commit for given revision' do
          expect(workspace.local_commit.oid).to eq initial_revision
        end
      end

      context 'branch' do
        let(:workspace) { Dandelion::Workspace.new(test_repo, adapter, revision: 'master') }

        it 'returns commit for given revision' do
          expect(workspace.local_commit.oid).to eq head_revision
        end
      end
    end

    context 'invalid revision specified' do
      let(:workspace) { Dandelion::Workspace.new(test_repo, adapter, revision: 'abcdef' ) }

      it 'raises revision error' do
        expect { workspace.local_commit }.to raise_error(Dandelion::RevisionError)
      end
    end
  end

  describe '#remote_commit' do
    before(:each) do
      allow(adapter).to receive(:read).with('.revision').and_return(initial_revision)
    end

    it 'returns commit for revision read from adapter' do
      expect(workspace.remote_commit.oid).to eq initial_revision
    end
  end

  describe '#remote_commit=' do
    it 'writes commit revision to adapter' do
      allow(adapter).to receive(:write).with('.revision', head_revision)
      workspace.remote_commit = workspace.local_commit
    end
  end

  describe '#tree' do
    it 'returns tree for repo and local commit' do
      tree = double()
      expect(Dandelion::Tree).to receive(:new).with(test_repo, workspace.local_commit).and_return(tree)
      expect(workspace.tree).to eq tree
    end
  end

  describe '#changeset' do
    it 'returns changeset for tree and remote commit' do
      changeset = double('changeset')
      tree = double('tree')
      remote_commit = double('remote_commit')

      allow(workspace).to receive(:tree).and_return(tree)
      allow(workspace).to receive(:remote_commit).and_return(remote_commit)

      allow(Dandelion::Changeset).to receive(:new).with(tree, remote_commit, workspace.config).and_return(changeset)

      expect(workspace.changeset).to eq changeset
    end
  end
end
