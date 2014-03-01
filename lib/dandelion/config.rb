require 'yaml'

module Dandelion
  class Config
    attr_reader :data
    
    def initialize(path)
      @path = path
      @data = YAML.load_file(path) || {}
    end

    def [](key)
      @data[key] || @data[key.to_s]
    end

    def []=(key, value)
      @data[key.to_s] = value
    end

    def merge(data)
      @data = @data.merge(data)
      self
    end
  end
end