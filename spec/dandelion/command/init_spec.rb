require 'spec_helper'

describe Dandelion::Command::Init do
  let(:revision) { 'e289ff1e2729839759dbd6fe99b6e35880910c7c' }

  describe '#execute!' do
    let(:adapter) { Dandelion::Adapter::NoOpAdapter.new({}) }
    let(:workspace) { Dandelion::Workspace.new(test_repo, adapter) }
    let(:command) { described_class.new(workspace, {}, {}) }

    before { command.setup([revision]) }

    it 'sets remote revision to specified revision' do
      expect(workspace).to receive(:remote_commit=).with(workspace.lookup(revision))
      command.execute!
    end
  end
end
