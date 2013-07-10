require 'dandelion/git'
require 'test/unit'

class TestGit < Test::Unit::TestCase
  def setup
    @repo = Dandelion::Git::Repo.new(File.join(File.dirname(__FILE__), 'test_git.git'))
  end

  def test_tree_files
    tree = Dandelion::Git::Tree.new(@repo, 'HEAD', '')
    files = ['foo', 'bar', 'baz/foo', 'baz/bar']
    assert_equal files.sort, tree.files.sort
  end

  def test_tree_subfolder
    tree = Dandelion::Git::Tree.new(@repo, 'HEAD', 'baz')
    files = ['foo', 'bar']
    assert_equal files.sort, tree.files.sort
  end

  def test_tree_show
    tree = Dandelion::Git::Tree.new(@repo, 'HEAD', '')
    assert_equal "bar\n", tree.show('foo')
    assert_equal "bar\n", tree.show('baz/foo')
  end

  def test_tree_revision
    revision = 'ff1f1d4bd0c99e1c9cca047c46b2194accf89504'
    tree = Dandelion::Git::Tree.new(@repo, revision, '')
    assert_equal revision, tree.revision
  end

  def test_diff_changed
    from = 'ff1f1d4bd0c99e1c9cca047c46b2194accf89504'
    to = '88d4480861346093048e08ce8dcc577d8aa69379'
    files = ['foo', 'baz/foo']
    diff = Dandelion::Git::Diff.new(@repo, from, to)
    assert_equal files.sort, diff.changed.sort
    assert_equal [], diff.deleted
  end

  def test_diff_deleted
    from = 'f55f3c44c89e5d215fbaaef9d33563117fe0b61b'
    to = '0ca605e9f0f1d42ce8193ac36db11ec3cc9efc08'
    files = ['test_delete']
    diff = Dandelion::Git::Diff.new(@repo, from, to)
    assert_equal files.sort, diff.deleted.sort
    assert_equal [], diff.changed
  end
end
