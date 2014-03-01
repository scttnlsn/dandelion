require 'optparse'

module Dandelion
  class CLI
    def initialize(args)
      @args = args
      @options = {}
      @parser = Command::Base.parser(@options)
    end

    def config
      @config ||= Config.new(config_path).tap do |config|
        config[:adapter] ||= config[:scheme] # backward compat
      end
    end

    def adapter
      @adapter ||= Adapter::Base.create_adapter(config[:adapter], config)
    rescue Adapter::InvalidAdapterError => e
      log.fatal("Unsupported adapter: #{config[:adapter]}")
      exit 1
    rescue Adapter::MissingDependencyError => e
      log.fatal("The #{command.config[:adapter]} adapter requires additional gems:")
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
      parse!(@parser)

      if @options[:help]
        display_help
        exit
      end

      if @options[:version]
        log.info("Dandelion #{Dandelion::VERSION}")
        exit
      end

      validate!

      parse!(command_class.parser(@options))

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
      @options[:config] || File.join(repo_path, 'dandelion.yml')
    end

    def repo_path
      if @options[:repo]
        File.expand_path(@options[:repo])
      else
        closest_repo(File.expand_path('.'))
      end
    end

    def validate!
      unless File.exists?(File.join(repo_path, '.git'))
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

    def closest_repo(dir)
      if File.exists?(File.join(dir, '.git'))
        dir
      else
        File.dirname(dir) != dir && closest_repo(File.dirname(dir)) || File.expand_path('.')
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