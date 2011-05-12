require 'aws/s3'

module Dandelion
  module Backend
    class S3 < Backend
      class << self
        def gems
          ['aws-s3']
        end
      end
      
      def initialize(access_key_id, secret_access_key, bucket_name, path)
        @access_key_id = access_key_id
        @secret_access_key = secret_access_key
        @bucket_name = bucket_name
        @path = path
      end

      def read(file)
        s3connect!
        raise MissingFileError unless AWS::S3::S3Object.exists? path(file), @bucket_name
        AWS::S3::S3Object.value path(file), @bucket_name
      end

      def write(file, data)
        s3connect!
        AWS::S3::S3Object.store path(file), data, @bucket_name
      end

      def delete(file)
        s3connect!
        AWS::S3::S3Object.delete path(file), @bucket_name
      end
      
      def to_s
        "s3://#{@access_key_id}@#{@bucket_name}/#{@path}"
      end

      protected
      
      def s3connect!
        AWS::S3::Base.establish_connection!(:access_key_id => @access_key_id, :secret_access_key => @secret_access_key, :use_ssl => true) unless AWS::S3::Base.connected? 
      end
            
      def path(file)
        if @path and !@path.empty?
          "#{@path}/file"
        else
          file
        end
      end
    end
  end
end