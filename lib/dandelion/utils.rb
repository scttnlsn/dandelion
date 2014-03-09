require 'tempfile'

module Dandelion
  module Utils
    def temp(file, data)
      tmp = Tempfile.new(file.gsub('/', '.'))
      tmp << data
      tmp.flush
      yield(tmp.path)
      tmp.close
    end
  end
end