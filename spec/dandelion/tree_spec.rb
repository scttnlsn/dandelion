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

    context 'symlink' do
      let(:repo) { test_repo('repo_symlink') }
      let(:tree) { test_tree(repo: repo, commit: repo.lookup('4c19bbe7ba04230a0ae2281c1abbc48a76a66550')) }

      it 'returns content of link source path' do
        expect(tree.data('link')).to eq "bar\n"
      end
    end

    context 'submodule' do
      let(:repo) { test_repo('repo_submodule') }
      let(:tree) { test_tree(repo: repo, commit: repo.lookup('ed393d7ff451fb04e9ea7c435e09303783106015')) }

      it 'does not raise error' do
        tree.data('repo')
      end
    end
  end
end
