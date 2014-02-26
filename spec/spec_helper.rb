require 'dandelion'
require 'rugged'

Dandelion.logger.level = Logger::UNKNOWN

def test_repo
  path = File.join(File.dirname(__FILE__), 'fixtures', 'repo.git')
  @repo ||= Rugged::Repository.new(path)
end

def test_diff
  from_commit = test_repo.lookup('e289ff1e2729839759dbd6fe99b6e35880910c7c')
  to_commit = test_repo.lookup('3d9b743acb4a84dd99002d2c6f3fcf1a47e9f06b')
  Dandelion::Diff.new(from_commit, to_commit)
end