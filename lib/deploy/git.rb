require 'grit'

module Git

  class Diff
  
    attr_reader :revision
  
    def initialize(dir, revision)
      @revision = revision
      @raw = `cd #{dir}; git diff --name-status #{@revision} HEAD`
    end

    def changed
      files_flagged ['A', 'C', 'M']
    end

    def deleted
      files_flagged ['D']
    end

    private

    def files_flagged(statuses)
      items = []
      @raw.split("\n").each do |line|
        status, file = line.split("\t")
        items << file if statuses.include? status
      end
      items
    end

  end

  class Tree

    def initialize(dir, revision)
      @dir = dir
      @commit = Grit::Repo.new(dir).commit(revision)
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