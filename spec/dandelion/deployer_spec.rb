require 'spec_helper'

describe Dandelion::Deployer do
  let(:adapter) { double('adapter') }
  let(:deployer) { Dandelion::Deployer.new(test_repo, adapter) }

  describe '#deploy!' do
    it 'perfoms writes and deletions on adapter' do
      adapter.should_receive(:write).with('baz/bar', "bar\n")
      adapter.should_receive(:write).with('foo', "foo\n")
      adapter.should_receive(:write).with('qux', '')

      adapter.should_receive(:delete).with('bar')
      adapter.should_receive(:delete).with('baz/foo')

      deployer.deploy!(test_diff)
    end
  end
end