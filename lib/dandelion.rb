module Dandelion
  class << self
    def logger
      return @log if @log
      $stdout.sync = true
      @log = Logger.new($stdout)
      @log.level = Logger::DEBUG
      @log.formatter = formatter
      @log
    end
    
    private
    
    def formatter
      proc do |severity, datetime, progname, msg| 
        "#{msg}\n"
      end
    end
  end
end
