module Dandelion
  class Change
    attr_reader :path, :type
    attr_accessor :type
    
    def initialize(path, type, read = nil)
      @path = path
      @type = type
      @read = read
    end

    def data
      @read.() if @read
    end
  end
end