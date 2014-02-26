require 'yaml'

module Dandelion
  module Command
    class Base
      class << self
        @@commands = {}

        def command(name)
          @@commands[name] = self
        end

        def create_command(name, options = {})
          klass = @@commands[name]
          return nil if klass.nil?
          klass.new(options)
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

      def initialize(options)
        @options = options
      end

      def config
        @config ||= YAML.load_file(@options[:config])
      end

      def repo
        @repo ||= Rugged::Repository.new(@options[:repo])
      end
    end
  end
end