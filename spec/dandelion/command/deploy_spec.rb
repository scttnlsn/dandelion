require 'spec_helper'

describe Dandelion::Command::Deploy do
  describe '#parser' do
    let(:options) { {} }
    let(:parser) { Dandelion::Command::Deploy.parser(options) }

    it 'parses dry flag' do
      expect(options[:dry]).to eq nil
      parser.order!(['--dry-run'])
      expect(options[:dry]).to eq true
    end
  end

  describe '#deployer' do
    let(:repo) { double() }
    let(:adapter) { double() }
    let(:config) { double() }

    let(:command) { Dandelion::Command::Deploy.new }

    it 'creates deployer for repo, adapter and config' do
      command.stub(:repo).and_return(repo)
      command.stub(:adapter).and_return(adapter)
      command.stub(:config).and_return(config)

      deployer = double()
      Dandelion::Deployer.should_receive(:new).with(repo, adapter, config).and_return(deployer)
      expect(command.deployer).to eq deployer
    end

    context 'dry run' do
      it 'uses noop adapter' do
        command.stub(:options).and_return(dry: true)
        command.stub(:repo).and_return(repo)
        command.stub(:config).and_return(config)

        deployer = double()
        noop_adapter = double()
        Dandelion::Adapter::NoOpAdapter.should_receive(:new).and_return(noop_adapter)
        Dandelion::Deployer.should_receive(:new).with(repo, noop_adapter, config).and_return(deployer)
        expect(command.deployer).to eq deployer
      end
    end
  end

  describe '#execute!' do
    let(:deployer) { double() }
    let(:diff) { double() }
    let(:workspace) { double() }
    let(:adapter) { double() }
    let(:local_commit) { double() }

    let(:command) { Dandelion::Command::Deploy.new }

    before(:each) do
      diff.stub(:empty?).and_return(false)
      
      workspace.stub(:diff).and_return(diff)
      workspace.stub(:local_commit).and_return(local_commit)

      command.stub(:adapter).and_return(adapter)
      command.stub(:deployer).and_return(deployer)
      command.stub(:workspace).and_return(workspace)
    end

    it 'deploys workspace diff and sets remote commit' do
      deployer.should_receive(:deploy!).with(diff)
      workspace.should_receive(:remote_commit=).with(workspace.local_commit)
      command.execute!
    end
  end
end