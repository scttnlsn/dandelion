require 'spec_helper'

describe Dandelion::Deployer do
  let(:adapter) { double('adapter') }
  let(:deployer) { Dandelion::Deployer.new(adapter) }

  describe '#deploy_changeset!' do
    let(:changeset) {[
      double(path: 'foo', data: 'bar', type: :write),
      double(path: 'bar/baz', data: 'baz', type: :write),
      double(path: 'qux', type: :delete)
    ]}

    it 'perfoms writes and deletions on adapter' do
      adapter.should_receive(:write).with('foo', 'bar')
      adapter.should_receive(:write).with('bar/baz', 'baz')
      adapter.should_receive(:delete).with('qux')

      deployer.deploy_changeset!(changeset)
    end

    context 'excluded' do
      let(:deployer) { Dandelion::Deployer.new(adapter, exclude: ['foo']) }

      it 'perfoms writes and deletions on adapter' do
        adapter.should_receive(:write).with('bar/baz', 'baz')
        adapter.should_receive(:delete).with('qux')

        deployer.deploy_changeset!(changeset)
      end
    end
  end

  describe '#deploy_files!' do
    before(:each) do
      IO.stub(:read).with('a.txt').and_return('A')
      IO.stub(:read).with('b.txt').and_return('B')
      IO.stub(:read).with('c/a.txt').and_return('cA')
      IO.stub(:read).with('c/b.txt').and_return('cB')
    end

    context 'local paths' do
      let(:files) { ['a.txt', 'b.txt'] }

      it 'performs writes on adapter' do
        adapter.should_receive(:write).with('a.txt', 'A')
        adapter.should_receive(:write).with('b.txt', 'B')

        deployer.deploy_files!(files)
      end
    end

    context 'local and remote paths' do
      let(:files) {[
        { 'a.txt' => 'files/a.txt' },
        { 'b.txt' => 'files/b.txt' }
      ]}

      it 'performs writes on adapter' do
        adapter.should_receive(:write).with('files/a.txt', 'A')
        adapter.should_receive(:write).with('files/b.txt', 'B')

        deployer.deploy_files!(files)
      end
    end

    context 'directory' do
      let(:files) {[
        { 'c/' => 'C/' }
      ]}

      before(:each) do
        File.stub(:directory?).with('c/').and_return(true)
        File.stub(:directory?).with('c/a.txt').and_return(false)
        File.stub(:directory?).with('c/b.txt').and_return(false)
        Dir.stub(:glob).with('c/**/*').and_return(['c/a.txt', 'c/b.txt'])
      end

      it 'performs writes on adapter' do
        adapter.should_receive(:write).with('C/a.txt', 'cA')
        adapter.should_receive(:write).with('C/b.txt', 'cB')

        deployer.deploy_files!(files)
      end
    end
  end
end