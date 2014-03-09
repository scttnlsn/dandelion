module Dandelion
  class Change
    attr_reader :path, :type, :data
    
    def initialize(path, type, data = nil)
      @path = path
      @type = type
      @data = data
    end
  end
end