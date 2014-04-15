require 'erb'
require 'yaml'

module Dandelion
  class Config
    attr_reader :path, :data
    
    def initialize(options = {})
      @path = options[:path]
      @data = @path ? load : (options[:data] || {})
    end

    def [](key)
      @data[key] || @data[key.to_s]
    end

    def []=(key, value)
      @data[key.to_s] = value
    end

    def defaults(values)
      values.each do |k, v|
        if self[k].nil?
          self[k] = v
        end
      end

      self
    end

  private

    def load
      YAML.load(template.result(binding)) || {}
    end

    def content
      IO.read(path)
    end

    def template
      ERB.new(content)
    end
  end
end