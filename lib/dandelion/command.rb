require 'optparse'

module Dandelion
  module Command
    class InvalidCommandError < StandardError; end

    class Base
      class << self
        @@commands = {}

        def command(name)
          @@commands[name] = self
        end

        def commands
          @@commands.keys
        end

        def lookup(name)
          raise InvalidCommandError.new(name) unless @@commands[name]
          @@commands[name]
        end

        def parser(options)
          OptionParser.new do |opts|
            opts.banner = 'Usage: dandelion [options] <command> [<args>]'

            options[:version] = false
            opts.on('-v', '--version', 'Dispay the current version') do
              options[:version] = true
            end

            options[:help] = false
            opts.on('-h', '--help', 'Display this help info') do
              options[:help] = true
            end

            options[:repo] = nil
            opts.on('--repo=[REPO]', 'Use the given repository') do |repo|
              options[:repo] = repo
            end

            options[:config] = nil
            opts.on('--config=[CONFIG]', 'Use the given config file') do |config|
              options[:config] = config
            end
          end
        end
      end

      attr_reader :workspace, :config, :options

      def initialize(workspace, config, options = {})
        @workspace = workspace
        @config = config
        @options = options
      end

      def setup(args)
      end

      def adapter
        workspace.adapter
      end

      def log
        Dandelion.logger
      end
    end
  end
end

require 'dandelion/command/deploy'
require 'dandelion/command/status'