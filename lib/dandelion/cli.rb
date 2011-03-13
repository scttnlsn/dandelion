require 'dandelion'
require 'dandelion/deployment'
require 'dandelion/git'
require 'dandelion/service'
require 'dandelion/version'
require 'optparse'
require 'yaml'

module Dandelion
  module Cli
    class UnsupportedSchemeError < StandardError; end
    
    class Options
      def initialize
        @options = {}
        @optparse = OptionParser.new do |opts|
          opts.banner = 'Usage: dandelion [options] [config_file]'

          @options[:force] = false
          opts.on('-f', '--force', 'Force deployment') do
            @options[:force] = true
          end

          @options[:status] = false
          opts.on('-s', '--status', 'Display revision status') do
            @options[:status] = true;
          end

          opts.on('-v', '--version', 'Display the current version') do
            puts "Dandelion v#{Dandelion::VERSION}"
            exit
          end

          opts.on('-h', '--help', 'Display this screen') do
            puts opts
            exit
          end
        end
      end
      
      def parse!(args)
        @args = args
        @optparse.parse!(@args)
      end
      
      def config_file
        if @args[0]
          @args[0].strip
        else
          'dandelion.yml'
        end
      end
      
      def [](key)
        @options[key]
      end

      def []=(key, value)
        @options[key] = value
      end
    end
    
    class Main
      class << self
        def execute(args)
          new(args).execute!
        end
      end
      
      def initialize(args)
        @options = Options.new
        @options.parse!(args)
      end
      
      def log
        Dandelion.logger
      end
      
      def check_files!
        unless File.exists? '.git'
          log.fatal('Not a git repository: .git')
          exit
        end
        unless File.exists? @options.config_file
          log.fatal("Could not find file: #{@options.config_file}")
          exit
        end
      end

      def service(config)
        if config['scheme'] == 'sftp'
          Service::SFTP.new(config['host'], config['username'], config['password'], config['path'])
        else
          raise UnsupportedSchemeError
        end
      end
      
      def execute!
        check_files!
        config = YAML.load_file @options.config_file

        begin
          service = service config
        rescue UnsupportedSchemeError
          log.fatal("Unsupported scheme: #{config['scheme']}")
          exit
        end

        log.info("Connecting to:    #{service.uri}")
        repo = Git::Repo.new('.')

        begin
          deployment = Deployment::DiffDeployment.new(repo, service, config['exclude'])
        rescue Deployment::RemoteRevisionError
          deployment = Deployment::FullDeployment.new(repo, service, config['exclude'])
        rescue Git::DiffError
          log.fatal('Error: could not generate diff')
          log.fatal('Try merging remote changes before running dandelion again')
          exit
        end
        
        begin
          repo.remote_list.each do |remote|
            deployment.validate_state(remote)
          end
        rescue Deployment::FastForwardError
          if !@options[:force] and !@options[:status]
            log.warn('Warning: you are trying to deploy unpushed commits')
            log.warn('This could potentially prevent others from being able to deploy')
            log.warn('If you are sure you want to this, use the -f option to force deployment')
            exit
          end
        end

        remote_revision = deployment.remote_revision || '---'
        local_revision = deployment.local_revision

        log.info("Remote revision:  #{remote_revision}")
        log.info("Local revision:   #{local_revision}")

        if @options[:status]
          exit
        end

        deployment.deploy!
        log.info("Deployment complete")
      end
    end
  end
end