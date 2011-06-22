require 'dandelion/command'

module Dandelion
  class Application
    class << self
      def execute(args)
        new(args).execute
      end
    end

    def initialize(args)
      @args = args
      @options = {}
      @parser = OptionParser.new
    end

    def execute
      global = Command::Base.parser(@options)
      parse(global)

      begin
        name = @args.shift
        command = Command::Base.create(name)
        parse(command.parser(@options))
      rescue Command::InvalidCommandError
        log.fatal("Invalid command: #{name}")
        log.fatal(global.help)
        log.fatal("Available commands:")
        log.fatal(Command::Base.commands.map { |name| "    #{name}" }.join("\n"))
        exit 1
      end
      
      prepare
      validate
      
      command.new(@options) do |cmd|
        cmd.setup(@args) if cmd.respond_to?(:setup)
        cmd.execute
      end
    end
    
    def log
      Dandelion.logger
    end

    private

    def parse(parser)
      begin
        parser.order!(@args)
      rescue OptionParser::InvalidOption => e
        log.fatal(e.to_s.capitalize)
        log.fatal(parser.help)
        exit 1
      end
    end
    
    def prepare
      @options[:config] ||= File.join(@options[:repo], 'dandelion.yml')
    end
    
    def validate
      unless File.exists?(File.join(@options[:repo], '.git'))
        log.fatal("Not a git repository: #{@options[:repo]}")
        exit 1
      end
      unless File.exists?(@options[:config])
        log.fatal("Could not find file: #{@options[:config]}")
        exit 1
      end
    end
  end
end