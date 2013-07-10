require 'grit'

module Dandelion
  module Git
    class DiffError < StandardError; end
    class RevisionError < StandardError; end

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
          @files = parse(diff)
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

      def diff
        @repo.git.native(:diff, {:name_status => true, :raise => true}, from_revision, to_revision)
      end

      def parse(diff)
        files = {}
        diff.split("\n").each do |line|
          status, file = line.split("\t")
          files[file] = status
        end
        files
      end
    end

    class Tree
      def initialize(repo, revision, local_path)
        @repo = repo
        @commit = @repo.commit(revision)
        @local_path = local_path
        raise RevisionError if @commit.nil?
        @tree = @commit.tree
      end

      def files
        Dir.chdir @local_path unless @local_path.nil?
        @repo.git.native(:ls_files, {:base => false, :o => true, :c => true}).split("\n")
      end

      def show(file)
        file
      end

      def revision
        @commit.sha
      end
    end
  end
end
