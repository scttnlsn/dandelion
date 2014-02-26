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

    let(:command) { Dandelion::Command::Deploy.new }

    it 'deploys workspace diff' do
      workspace.stub(:diff).and_return(diff)
      command.stub(:deployer).and_return(deployer)
      command.stub(:workspace).and_return(workspace)
      deployer.should_receive(:deploy!).with(diff)
      command.execute!
    end
  end
end