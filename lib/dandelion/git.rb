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

      def initialize(repo, from_revision, to_revision, local_path)
        @repo = repo
        @local_path = local_path
        @from_revision = from_revision
        @to_revision = to_revision
        unless @local_path.nil? || @local_path.empty?
          @from_revision = "#{@from_revision}:#{@local_path}"
          @to_revision = "#{@to_revision}:#{@local_path}"
        end
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
        @repo.git.native(:diff, {:name_status => true, :raise => true}, @from_revision, @to_revision)
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
        @revision = revision
        @local_path = local_path
        raise RevisionError if @commit.nil?
        @tree = @commit.tree
      end

      def files
        @revision = "#{@revision}:#{@local_path}" unless @local_path.nil? || @local_path.empty?
        @repo.git.native(:ls_tree, {:name_only => true, :full_tree => true, :r => true}, @revision).split("\n")
      end

      def show(file)
        @file = file
        @file = "#{@local_path}/#{file}" unless @local_path.nil? || @local_path.empty?
        if (@tree / "#{@file}").is_a?(Grit::Submodule)
          puts "#{file} is a submodule, ignoring."
          return
        end
        (@tree / "#{@file}").data
      end

      def revision
        @commit.sha
      end
    end
  end
end
