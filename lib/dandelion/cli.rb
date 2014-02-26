require 'optparse'

module Dandelion
  class CLI
    def initialize(args)
      @args = args
      @options = {}
      @parser = Command::Base.parser(@options)
    end

    def execute!
      parse(@parser)
      prepare

      if @options[:help]
        display_help
        exit
      end

      if @options[:version]
        log.info("Dandelion #{Dandelion::VERSION}")
        exit
      end

      validate

      command_name = @args.shift.to_sym
      command_class = Command::Base.lookup(command_name)

      if command_class.nil?
        log.fatal("Invalid command: #{command_name}")
        display_help
        exit 1
      end

      parse(command_class.parser(@options))

      command = command_class.new(@options)
      command.config[:adapter] ||= command.config[:scheme] # backward compat

      begin
        unless command.adapter
          log.fatal("Unsupported adapter: #{command.config[:adapter]}")
          exit 1
        end
      rescue Adapter::MissingDependencyError => e
        log.fatal("The #{command.config[:adapter]} adapter requires additional gems:")
        log.fatal(e.gems.map { |name| "    #{name}"}.join("\n"))
        log.fatal("Please install the gems first: gem install #{e.gems.join(' ')}")
        exit 1
      end

      command.setup(@args)
      command.execute!
    end

  private

    def prepare
      if @options[:repo]
        @options[:repo] = File.expand_path(@options[:repo])
      else
        @options[:repo] = closest_repo(File.expand_path('.'))
      end

      @options[:config] ||= File.join(@options[:repo], 'dandelion.yml')
    end

    def validate
      unless File.exists?(File.join(@options[:repo], '.git'))
        log.fatal("Not a git repository: #{@options[:repo]}")
        exit 1
      end

      unless File.exists?(@options[:config])
        log.fatal("Missing config file: #{@options[:config]}")
        exit 1
      end
    end

    def parse(parser)
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