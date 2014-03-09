require 'spec_helper'

describe Dandelion::Tree do
  let(:tree) { test_tree }

  it 'has a commit' do
    expect(tree.commit).to eq test_commits.last
  end

  describe '#data' do
    it 'returns blob content for path' do
      expect(tree.data('foo')).to eq "foo\n"
    end
  end
end