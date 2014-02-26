require 'optparse'
require 'yaml'

module Dandelion
  module Command
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

      attr_reader :options

      def initialize(options = {})
        @options = options
      end

      def setup(args)
      end

      def config
        return @config if @config

        @config = {}
        data = YAML.load_file(@options[:config]) || {}
        data.each_pair { |k, v| @config[k.to_sym] = v }
        @config
      end

      def repo
        @repo ||= Rugged::Repository.new(@options[:repo])
      end

      def adapter
        @adapter ||= Adapter::Base.create_adapter(config[:adapter], config)
      end

      def workspace
        @workspace ||= Workspace.new(repo, adapter, config)
      end

      def log
        Dandelion.logger
      end
    end
  end
end

require 'dandelion/command/deploy'
require 'dandelion/command/status'