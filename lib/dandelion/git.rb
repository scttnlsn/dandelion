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
        @from_revision = revision_string(from_revision)
        @to_revision = revision_string(to_revision)

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
        @repo.git.native(:diff, { :name_status => true, :raise => true }, @from_revision, @to_revision)
      end

      def parse(diff)
        files = {}
        diff.split("\n").each do |line|
          status, file = line.split("\t")
          files[file] = status
        end
        files
      end

      def revision_string(revision)
        if @local_path.nil? || @local_path.empty?
          revision
        else
          "#{revision}:#{@local_path}"
        end
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
        @repo.git.native(:ls_tree, { :name_only => true, :full_tree => true, :r => true }, revision_string).split("\n")
      end

      def show(file)
        blob = @tree / file_path(file)
        if blob.is_a?(Grit::Submodule)
          puts "#{file} is a submodule, ignoring."
        else
          blob.data
        end
      end

      def revision
        @commit.sha
      end

      private

      def file_path(file)
        if local_path?
          File.join(@local_path, file)
        else
          file
        end
      end

      def revision_string
        if local_path?
          "#{@revision}:#{@local_path}"
        else
          @revision
        end
      end

      def local_path?
        !@local_path.nil? && !@local_path.empty?
      end
    end
  end
end

# Grit does not support Ruby 2.0 right now
class String
  if ((defined? RUBY_VERSION) && (RUBY_VERSION[0..2] == "1.9" || RUBY_VERSION[0].to_i >= 2))
    def getord(offset); self[offset].ord; end
  else
    alias :getord :[]
  end
end