require 'dandelion'
require 'dandelion/deployment'
require 'dandelion/git'
require 'dandelion/service'
require 'dandelion/version'
require 'optparse'
require 'yaml'

module Dandelion
  module Cli
    class Options
      attr_reader :config_file
      
      def initialize
        @options = {}
        @config_file = 'dandelion.yml'
        @global = global_parser
        @commands = { 'deploy' => deploy_parser, 'status' => status_parser }
      end
      
      def parse(args)
        order @global, args
        command = args.shift
        if command and @commands[command]
          order @commands[command], args
        end
        
        if @commands.key? command
          @config_file = args.shift.strip if args[0]
          command
        else
          if not @command.nil?
            puts "Invalid command: #{command}"
          end
          puts @global.help
          puts "\nAvailable commands:\n    #{@commands.keys.join("\n    ")}"
          exit
        end
      end
      
      def [](key)
        @options[key]
      end

      def []=(key, value)
        @options[key] = value
      end
      
      private
      
      def global_parser
        OptionParser.new do |opts|
          opts.banner = 'Usage: dandelion [options] [[command] [options]]'

          opts.on('-v', '--version', 'Display the current version') do
            puts "Dandelion v#{Dandelion::VERSION}"
            exit
          end

          opts.on('-h', '--help', 'Display this screen') do
            puts opts
            exit
          end
          
          @options[:repo] = '.'
          opts.on('--repo=[REPO]', 'Use the given repository') do |repo|
            @options[:repo] = repo
          end
        end
      end
      
      def deploy_parser
        OptionParser.new do |opts|
          opts.banner = 'Usage: dandelion deploy [options]'
          
          @options[:force] = false
          opts.on('-f', '--force', 'Force deployment') do
            @options[:force] = true
          end
        end
      end
      
      def status_parser
        OptionParser.new do |opts|
          opts.banner = 'Usage: dandelion status'
        end
      end
      
      def order(parser, args)
        begin
          parser.order!(args)
        rescue OptionParser::InvalidOption => e
          puts e.to_s.capitalize
          puts parser.help
          exit
        end
      end
    end
    
    class Main
      class << self
        def execute(args)
          new(args).execute
        end
      end
      
      def initialize(args)
        @options = Options.new
        @command = @options.parse args
        
        validate_files
        @config = YAML.load_file(File.expand_path @options.config_file)
        @repo = Git::Repo.new(File.expand_path @options[:repo])
      end
      
      def log
        Dandelion.logger
      end
      
      def execute
        log.info("Connecting to:    #{service.uri}")
        deployment(service) do |d|
          log.info("Remote revision:  #{d.remote_revision || '---'}")
          log.info("Local revision:   #{d.local_revision}")
          
          if @command == 'status'
            exit
          elsif @command == 'deploy'
            validate_deployment d
            d.deploy
            log.info("Deployment complete")
          end
        end
      end
      
      private
      
      def deployment(service)
        begin
          deployment = Deployment::DiffDeployment.new(@repo, service, @config['exclude'])
        rescue Deployment::RemoteRevisionError
          deployment = Deployment::FullDeployment.new(@repo, service, @config['exclude'])
        rescue Git::DiffError
          log.fatal('Error: could not generate diff')
          log.fatal('Try merging remote changes before running dandelion again')
          exit
        end
        if block_given?
          yield(deployment)
        else
          deployment
        end
      end
      
      def service
        if @config['scheme'] == 'sftp'
          Service::SFTP.new(@config['host'], @config['username'], @config['password'], @config['path'])
        elsif @config['scheme'] == 'ftp'
          Service::FTP.new(@config['host'], @config['username'], @config['password'], @config['path'])
        else
          log.fatal("Unsupported scheme: #{@config['scheme']}")
          exit
        end
      end
      
      def validate_deployment(deployment)
        begin
          @repo.remote_list.each do |remote|
            deployment.validate_state(remote)
          end
        rescue Deployment::FastForwardError
          if !@options[:force]
            log.warn('Warning: you are trying to deploy unpushed commits')
            log.warn('This could potentially prevent others from being able to deploy')
            log.warn('If you are sure you want to this, use the -f option to force deployment')
            exit
          end
        end
      end
      
      def validate_files
        unless File.exists? File.expand_path File.join(@options[:repo], '.git')
          log.fatal("Not a git repository: #{@options[:repo]}")
          exit
        end
        unless File.exists?(File.expand_path @options.config_file)
          log.fatal("Could not find file: #{@options.config_file}")
          exit
        end
      end
    end
  end
end