module Dandelion
  class << self
    def logger
      return @log if @log
      @log = Logger.new(STDOUT)
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
