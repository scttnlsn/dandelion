require 'logger'
require 'rugged'
require 'dandelion/adapter'
require 'dandelion/cli'
require 'dandelion/command'
require 'dandelion/diff'
require 'dandelion/deployer'
require 'dandelion/version'
require 'dandelion/workspace'

module Dandelion
  class << self
    def logger
      return @logger if @logger

      $stdout.sync = true

      @logger = Logger.new($stdout)
      @logger.level = Logger::DEBUG
      @logger.formatter = formatter
      @logger
    end

  private

    def formatter
      proc do |severity, datetime, progname, msg|
        "#{msg}\n"
      end
    end
  end
end