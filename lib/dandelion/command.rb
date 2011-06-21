require 'dandelion'
require 'dandelion/backend'
require 'dandelion/deployment'
require 'dandelion/git'
require 'dandelion/version'
require 'optparse'
require 'yaml'

module Dandelion
  module Command
    class InvalidCommandError < StandardError; end
    
    class Base
      class << self
        @@commands = {}

        def command(name)
          @@commands[name] = self
        end

        def create(name)
          Dir.glob(File.join(File.dirname(__FILE__), 'command', '*.rb')) { |file| require file }
          raise InvalidCommandError unless @@commands.include?(name)
          @@commands[name]
        end
        
        def commands
          @@commands.keys
        end

        def parser(options)
          OptionParser.new do |opts|
            opts.banner = 'Usage: dandelion [options] [[command] [options]]'

            opts.on('-v', '--version', 'Display the current version') do
              puts "Dandelion #{Dandelion::VERSION}"
              exit
            end

            opts.on('-h', '--help', 'Display this screen') do
              puts opts
              exit
            end

            options[:repo] = closest_repo(File.expand_path('.'))
            opts.on('--repo=[REPO]', 'Use the given repository') do |repo|
              options[:repo] = repo
            end
            
            options[:config] = nil
            opts.on('--config=[CONFIG]', 'Use the given configuration file') do |config|
              options[:config] = config
            end
          end
        end
        
        private
        
        def closest_repo(dir)
          if File.exists?(File.join(dir, '.git'))
            dir
          else
            File.dirname(dir) != dir && closest_repo(File.dirname(dir))
          end
        end
      end

      def initialize(options)
        @options = options        
        @config = YAML.load_file(File.expand_path(@options[:config]))
        @repo = Git::Repo.new(File.expand_path(@options[:repo]))
        
        yield(self) if block_given?
      end
      
      protected
      
      def log
        Dandelion.logger
      end

      def backend
        begin
          backend = Backend::Base.create(@config)
          log.info("Connecting to #{backend}")
          backend
        rescue Backend::MissingDependencyError => e
          log.fatal("The '#{@config['scheme']}' scheme requires additional gems:")
          log.fatal(e.gems.map { |name| "    #{name}" }.join("\n"))
          log.fatal("Please install the gems: gem install #{e.gems.join(' ')}")
          exit 1
        rescue Backend::UnsupportedSchemeError
          log.fatal("Unsupported scheme: #{@config['scheme']}")
          exit 1
        end
      end
    
      def deployment(revision, backend = nil)
        begin
          backend ||= backend()
          Deployment::Deployment.create(@repo, backend, @config['exclude'], revision)
        rescue Git::DiffError
          log.fatal('Error: could not generate diff')
          log.fatal('Try merging remote changes before running dandelion again')
          exit 1
        end
      end
      
      def validate(deployment)
        begin
          @repo.remote_list.each do |remote|
            deployment.validate_state(remote)
          end
        rescue Deployment::FastForwardError
          if !@options[:force]
            log.warn('Warning: you are trying to deploy unpushed commits')
            log.warn('This could potentially prevent others from being able to deploy')
            log.warn('If you are sure you want to this, use the -f option to force deployment')
            exit 1
          end
        end
      end
    end
  end
end