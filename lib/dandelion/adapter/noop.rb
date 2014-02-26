module Dandelion
  module Adapter
    class NoOpAdapter < Adapter::Base
      def read(path)
      end
      
      def write(path, data)
      end

      def delete(path)
      end
    end
  end
end