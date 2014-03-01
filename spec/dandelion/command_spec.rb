require 'spec_helper'

describe Dandelion::Command::Base do
  let(:workspace) { double('workspace', adapter: double('adapter')) }
  let(:config) { double('config') }
  let(:options) { double('options') }

  let(:command) { Dandelion::Command::Base.new(workspace, config, options) }

  it 'registers command classes' do
    class TestCommand < Dandelion::Command::Base
      command :test
    end

    expect(Dandelion::Command::Base.lookup(:test)).to eq TestCommand
  end

  it 'raises error on invalid command' do
    expect {
      Dandelion::Command::Base.lookup(:another)
    }.to raise_error(Dandelion::Command::InvalidCommandError)
  end

  it 'has workspace' do
    expect(command.workspace).to eq workspace
  end

  it 'has config' do
    expect(command.config).to eq config
  end

  it 'has options' do
    expect(command.options).to eq options
  end

  describe '#adapter' do
    it 'returns workspace adapter' do
      expect(command.adapter).to eq workspace.adapter
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

    it 'parses log level' do
      parser.order!(['--log=warn'])
      expect(Dandelion.logger.level).to eq Logger::WARN
    end
  end
end