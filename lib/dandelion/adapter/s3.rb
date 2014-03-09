module Dandelion
  module Adapter
    class S3 < Adapter::Base
      adapter 's3'
      requires_gems 'aws-s3'
      
      def initialize(config)
        require 'aws/s3'
        
        @access_key_id = config[:access_key_id]
        @secret_access_key = config[:secret_access_key]
        @bucket_name = config[:bucket_name]
        @host = config[:host]
        @path = config[:path]
      end

      def read(file)
        s3connect!
        return nil unless AWS::S3::S3Object.exists?(path(file), @bucket_name)
        AWS::S3::S3Object.value(path(file), @bucket_name)
      end

      def write(file, data)
        s3connect!
        AWS::S3::S3Object.store(path(file), data, @bucket_name)
      end

      def delete(file)
        s3connect!
        AWS::S3::S3Object.delete(path(file), @bucket_name)
      end
      
      def to_s
        "s3://#{@access_key_id}@#{@bucket_name}/#{@path}"
      end

      protected
      
      def s3connect!
        options = {
          access_key_id: @access_key_id,
          secret_access_key: @secret_access_key,
          use_ssl: true
        }

        options[:server] = @host if @host
        AWS::S3::Base.establish_connection!(options) unless AWS::S3::Base.connected?
      end
            
      def path(file)
        if @path and !@path.empty?
          "#{@path}/#{file}"
        else
          file
        end
      end
    end
  end
end