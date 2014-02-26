require 'spec_helper'

describe Dandelion::Command::Base do
  it 'registers command classes' do
    class TestCommand < Dandelion::Command::Base
      command :test
    end

    expect(Dandelion::Command::Base.create_command(:test)).to be_a(TestCommand)
  end

  describe '#config' do
    let(:command) { Dandelion::Command::Base.new(config: 'foo') }

    it 'parses yaml config file' do
      YAML.should_receive(:load_file).with('foo').and_return('bar')
      expect(command.config).to eq 'bar'
    end
  end

  describe '#repo' do
    let(:command) { Dandelion::Command::Base.new(repo: 'foo') }

    it 'creates repository object' do
      Rugged::Repository.should_receive(:new).with('foo').and_return('bar')
      expect(command.repo).to eq 'bar'
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