require 'spec_helper'

describe Dandelion::Deployer do
  let(:adapter) { double('adapter') }
  let(:deployer) { Dandelion::Deployer.new(adapter) }

  describe '#deploy!' do
    let(:changeset) {[
      double(path: 'foo', data: 'bar', type: :write),
      double(path: 'bar/baz', data: 'baz', type: :write),
      double(path: 'qux', type: :delete)
    ]}

    it 'perfoms writes and deletions on adapter' do
      adapter.should_receive(:write).with('foo', 'bar')
      adapter.should_receive(:write).with('bar/baz', 'baz')
      adapter.should_receive(:delete).with('qux')

      deployer.deploy!(changeset)
    end

    context 'excluded' do
      let(:deployer) { Dandelion::Deployer.new(adapter, exclude: ['foo']) }

      it 'perfoms writes and deletions on adapter' do
        adapter.should_receive(:write).with('bar/baz', 'baz')
        adapter.should_receive(:delete).with('qux')

        deployer.deploy!(changeset)
      end
    end
  end
end