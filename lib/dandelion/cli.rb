require 'optparse'

module Dandelion
  class CLI
    def initialize(args)
      @args = args

      @options = {}
      @options[:help] = true if @args.length == 0

      @parser = Command::Base.parser(@options)
    end

    def config
      @config ||= Config.new(path: config_path).tap do |config|
        config[:adapter] ||= config[:scheme] # backward compat
      end
    end

    def adapter
      @adapter ||= Adapter::Base.create_adapter(config[:adapter], config)
    rescue Adapter::InvalidAdapterError => e
      log.fatal("Unsupported adapter: #{config[:adapter]}")
      exit 1
    rescue Adapter::MissingDependencyError => e
      log.fatal("The #{config[:adapter]} adapter requires additional gems:")
      log.fatal(e.gems.map { |name| "    #{name}"}.join("\n"))
      log.fatal("Please install the gems first: gem install #{e.gems.join(' ')}")
      exit 1
    end

    def repo
      @repo ||= Rugged::Repository.new(repo_path)
    end

    def workspace
      @workspace ||= Workspace.new(repo, adapter, config)
    end

    def command_class
      @command_class ||= Command::Base.lookup(@args.shift.to_sym)
    rescue Command::InvalidCommandError => e
      log.fatal("Invalid command: #{e}")
      display_help
      exit 1
    end

    def execute!
      if @args.length == 0
        @options[:help] = true
      end

      parse!(@parser)

      if @options[:version]
        log.info("Dandelion #{Dandelion::VERSION}")
        exit
      end

      if @options[:help]
        display_help
        exit
      end

      parse!(command_class.parser(@options))

      validate!

      command = command_class.new(workspace, config, @options)
      command.setup(@args)

      begin
        command.execute!
      rescue RevisionError => e
        log.fatal("Invalid revision: #{e}")
        exit 1
      end
    end

    private

    def config_path
      if @options[:config]
        @options[:config]
      else
        paths = [
          File.join(repo_path, 'dandelion.yml'),
          File.join(repo_path, 'dandelion.yaml')
        ]

        paths.drop_while { |path| !path || !File.exists?(path) }.first || paths.first
      end
    end

    def repo_path
      if @options[:repo]
        File.expand_path(@options[:repo])
      else
        File.expand_path('.')
      end
    end

    def repo_exists?
      return !!(repo)
    rescue ::IOError, ::Rugged::OSError, ::Rugged::RepositoryError
      # squash exceptions for instantiating Rugged repo
      return false
    end

    def validate!
      unless repo_exists?
        log.fatal("Not a git repository: #{repo_path}")
        exit 1
      end

      unless File.exists?(config_path)
        log.fatal("Missing config file: #{config_path}")
        exit 1
      end
    end

    def parse!(parser)
      begin
        parser.order!(@args)
      rescue OptionParser::InvalidOption => e
        log.fatal(e.to_s.capitalize)
        display_help
        exit 1
      end
    end

    def display_help
      log.info(@parser.help)
      log.info("Available commands:")
      log.info(Command::Base.commands.map { |c| "    #{c}"}.join("\n"))
    end

    def log
      Dandelion.logger
    end
  end
end
