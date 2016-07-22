module Dandelion
  module Adapter
    class NoOpAdapter < Adapter::Base
      def read(path)
      end
      
      def write(path, data)
      end

      def delete(path)
      end

      def symlink(path, data)
      end
    end
  end
end