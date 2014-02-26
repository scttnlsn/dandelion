require 'spec_helper'

describe Dandelion::Command::Base do
  it 'registers command classes' do
    class TestCommand < Dandelion::Command::Base
      command :test
    end

    expect(Dandelion::Command::Base.lookup(:test)).to eq TestCommand
  end

  describe '#config' do
    let(:command) { Dandelion::Command::Base.new(config: 'foo') }

    it 'parses yaml config file' do
      config = {}
      YAML.should_receive(:load_file).with('foo').and_return(config)
      expect(command.config).to eq config
    end
  end

  describe '#repo' do
    let(:command) { Dandelion::Command::Base.new(repo: 'foo') }

    it 'creates repository object' do
      repo = double()
      Rugged::Repository.should_receive(:new).with('foo').and_return(repo)
      expect(command.repo).to eq repo
    end
  end

  describe '#adapter' do
    let(:command) { Dandelion::Command::Base.new }

    it 'creates adapter object from config' do
      command.stub(:config).and_return(adapter: 'foo')

      adapter = double();
      Dandelion::Adapter::Base.should_receive(:create_adapter).with('foo', command.config).and_return(adapter)
      expect(command.adapter).to eq adapter
    end
  end

  describe '#workspace' do
    let(:repo) { double() }
    let(:adapter) { double() }
    let(:config) { double() }

    let(:command) { Dandelion::Command::Base.new }

    it 'creates workspace from repo and adapter' do
      command.stub(:repo).and_return(repo)
      command.stub(:adapter).and_return(adapter)
      command.stub(:config).and_return(config)

      workspace = double()
      Dandelion::Workspace.should_receive(:new).with(repo, adapter, config).and_return(workspace)
      expect(command.workspace).to eq workspace
    end
  end

  describe '#parser' do
    let(:options) { {} }
    let(:parser) { Dandelion::Command::Base.parser(options) }

    it 'parses version flag' do
      expect(options[:version]).to_not be
      parser.order!(['-v'])
      expect(options[:version]).to be
    end

    it 'parses help flag' do
      expect(options[:help]).to_not be
      parser.order!(['-h'])
      expect(options[:help]).to be
    end

    it 'parses repo option' do
      expect(options[:repo]).to eq nil
      parser.order!(['--repo=foo'])
      expect(options[:repo]).to eq 'foo'
    end

    it 'parses config option' do
      expect(options[:config]).to eq nil
      parser.order!(['--config=foo'])
      expect(options[:config]).to eq 'foo'
    end
  end
end