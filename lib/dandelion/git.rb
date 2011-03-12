require 'grit'

module Dandelion
  module Git
    class DiffError < StandardError; end
  
    class Repo < Grit::Repo
      def initialize(dir)
        super(dir)
      end
    end
  
    class Diff
      attr_reader :from_revision, :to_revision
    
      @files = nil
  
      def initialize(repo, from_revision, to_revision)
        @repo = repo
        @from_revision = from_revision
        @to_revision = to_revision
        begin
          @files = parse_diff @repo.git.native(:diff, {:name_status => true, :raise => true}, from_revision, to_revision)
        rescue Grit::Git::CommandFailed
          raise DiffError
        end
      end

      def changed
        @files.to_a.select { |f| ['A', 'C', 'M'].include?(f.last) }.map { |f| f.first }
      end

      def deleted
        @files.to_a.select { |f| 'D' == f.last }.map { |f| f.first }
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

    class Tree
      def initialize(repo, revision)
        @repo = repo
        @commit = @repo.commit(revision)
        @tree = @commit.tree
      end
    
      def files
        @repo.git.native(:ls_tree, {:name_only => true, :r => true}, revision).split("\n")
      end

      def show(file)
        (@tree / file).data
      end
  
      def revision
        @commit.sha
      end
    end
  end
end