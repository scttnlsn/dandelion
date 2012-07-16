require 'dandelion'
require 'dandelion/deployment'
require 'test/unit'

def fixture(name)
  File.read(File.join(File.dirname(__FILE__), 'fixtures', name))
end

# Mock classes

class MockGit
  def native(cmd, options = {}, *args, &block)
    if cmd == :ls_tree
      fixture('ls_tree')
    elsif cmd == :diff
      fixture('diff')
    end
  end
end

class MockFile
  attr_reader :data
  
  def initialize(data)
    @data = data
  end
end

class MockTree
  def /(file)
    MockFile.new('bar')
  end
end

class MockCommit
  def initialize(revision)
    @revision = revision
  end
  
  def tree
    MockTree.new
  end
  
  def sha
    @revision
  end
end

class MockRepo
  def commit(revision)
    MockCommit.new(revision)
  end
  
  def git
    MockGit.new
  end
end

class MockBackend
  attr_reader :reads, :writes, :deletes
  
  def initialize(remote_revision)
    @reads = {'REVISION' => remote_revision}
    @writes = {}
    @deletes = []
  end
  
  def read(file)
    @reads[file]
  end
  
  def write(file, data)
    @writes[file] = data
  end
  
  def delete(file)
    @deletes << file
  end
end

# Tests

class TestDiffDeployment < Test::Unit::TestCase
  def setup
    Dandelion.logger.level = Logger::FATAL
    @head_revision = '0ca605e9f0f1d42ce8193ac36db11ec3cc9efc08'
    @remote_revision = 'ff1f1d4bd0c99e1c9cca047c46b2194accf89504'
    @repo = MockRepo.new
    @backend = MockBackend.new(@remote_revision)
    @diff_deployment = Dandelion::Deployment::DiffDeployment.new(@repo, @backend, :revision => @head_revision)
  end
  
  def test_diff_deployment_local_revision
    assert_equal @head_revision, @diff_deployment.local_revision
  end
  
  def test_diff_deployment_remote_revision
    assert_equal @remote_revision, @diff_deployment.remote_revision
  end
  
  def test_diff_deployment_write_revision
    @diff_deployment.write_revision
    assert_equal @head_revision, @backend.writes['REVISION']
  end
  
  def test_diff_deployment_revisions_match
    assert !@diff_deployment.revisions_match?
  end
  
  def test_diff_deployment_any
    assert @diff_deployment.any?
  end
  
  def test_diff_deployment_deploy
    @diff_deployment.deploy
    assert_equal 3, @backend.writes.length
    assert_equal 'bar', @backend.writes['foo']
    assert_equal 'bar', @backend.writes['baz/foo']
    assert_equal @head_revision, @backend.writes['REVISION']
    assert_equal ['foobar'], @backend.deletes
  end
end
