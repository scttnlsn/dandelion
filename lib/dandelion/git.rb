require 'grit'

module Git
  class DiffError < StandardError; end
  
  class Git
    def initialize(dir)
      @dir = dir
      @repo = Grit::Repo.new(dir)
    end
  end
  
  class Diff < Git
    attr_reader :revision
    
    @files = nil
  
    def initialize(dir, revision)
      super(dir)
      @revision = revision
      begin
        @files = parse_diff @repo.git.native(:diff, {:name_status => true, :raise => true}, revision, 'HEAD')
      rescue Grit::Git::CommandFailed
        raise DiffError
      end
    end

    def changed
      @files.select { |file, status| ['A', 'C', 'M'].include?(status) }.keys
    end

    def deleted
      @files.select { |file, status| 'D' == status }.keys
    end

    private
    
    def parse_diff(diff)
      files = {}
      diff.split("\n").each do |line|
        status, file = line.split("\t")
        files[file] = status
      end
      files
    end
  end

  class Tree < Git
    def initialize(dir, revision)
      super(dir)
      @commit = @repo.commit(revision)
      @tree = @commit.tree
    end
    
    def files
      `cd #{@dir}; git ls-tree --name-only -r #{revision}`.split("\n")
    end

    def show(file)
      (@tree / file).data
    end
  
    def revision
      @commit.sha
    end
  end
end