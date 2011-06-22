require 'dandelion/git'

module Dandelion
  module Deployment
    class RemoteRevisionError < StandardError; end
    class FastForwardError < StandardError; end
  
    class Deployment
      class << self
        def create(repo, backend, options)
          begin
            DiffDeployment.new(repo, backend, options)
          rescue RemoteRevisionError
            FullDeployment.new(repo, backend, options)
          end
        end
      end
      
      def initialize(repo, backend, options = {})
        @repo = repo
        @backend = backend
        @options = { :exclude => [], :revision => 'HEAD' }.merge(options)
        @tree = Git::Tree.new(@repo, @options[:revision])
        
        if @options[:dry]
          # Stub out the destructive backend methods
          def @backend.write(file, data); end
          def @beckend.delete(file); end
        end
      end
    
      def local_revision
        @tree.revision
      end
    
      def remote_revision
        nil
      end
    
      def write_revision
        @backend.write('.revision', local_revision)
      end
      
      def validate
        begin
          @repo.remote_list.each do |remote|
            raise FastForwardError if fast_forwardable(remote)
          end
        rescue Grit::Git::CommandFailed
        end
      end
      
      def log
        Dandelion.logger
      end
    
      protected
    
      def exclude_file?(file)
        return @options[:exclude].map { |e| file.start_with?(e) }.any?
      end
      
      private
      
      def fast_forwardable(remote)
        !(@repo.git.native(:remote, {:raise => true}, 'show', remote) =~ /fast-forward/i).nil?
      end
    end
  
    class DiffDeployment < Deployment
      def initialize(repo, backend, options = {})
        super(repo, backend, options)
        @diff = Git::Diff.new(@repo, read_remote_revision, @options[:revision])
      end
    
      def remote_revision
        @diff.from_revision
      end
    
      def deploy
        if !revisions_match? && any?
          deploy_changed
          deploy_deleted
        else
          log.info("Nothing to deploy")
        end
        unless revisions_match?
          write_revision
        end
      end
    
      def deploy_changed
        @diff.changed.each do |file|
          if exclude_file?(file)
            log.info("Skipping file: #{file}")
          else
            log.info("Uploading file: #{file}")
            @backend.write(file, @tree.show(file))
          end
        end
      end
    
      def deploy_deleted
        @diff.deleted.each do |file|
          if exclude_file?(file)
            log.info("Skipping file: #{file}")
          else
            log.info("Deleting file: #{file}")
            @backend.delete(file)
          end
        end
      end
    
      def any?
        @diff.changed.any? || @diff.deleted.any?
      end
    
      def revisions_match?
        remote_revision == local_revision
      end
    
      private
    
      def read_remote_revision
        begin
          @backend.read('.revision').chomp
        rescue Backend::MissingFileError
          raise RemoteRevisionError
        end
      end
    end
  
    class FullDeployment < Deployment
      def deploy
        @tree.files.each do |file|
          if exclude_file?(file)
            log.info("Skipping file: #{file}")
          else
            log.info("Uploading file: #{file}")
            @backend.write(file, @tree.show(file))
          end
        end
        write_revision
      end
    end
  end
end