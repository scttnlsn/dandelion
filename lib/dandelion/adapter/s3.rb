module Dandelion
  module Adapter
    class S3 < Adapter::Base
      adapter 's3'
      requires_gems 'aws-s3'

      def initialize(config)
        require 'aws/s3'

        @config = config
        @config.defaults(preserve_permissions: true)
      end

      def read(file)
        connect!
        return nil unless AWS::S3::S3Object.exists?(path(file), bucket_name)
        AWS::S3::S3Object.value(path(file), bucket_name)
      end

      def write(file, data)
        connect!

        key = path(file)

        begin
          policy = AWS::S3::S3Object.acl(key, bucket_name) if @config[:preserve_permissions]
        rescue AWS::S3::NoSuchKey
        end

        # Set caching options
        options = {}
        options[:cache_control] = "max-age=#{@config[:cache_control]}" if @config[:cache_control]
        options[:expires] = @config[:expires] if @config[:expires]

        AWS::S3::S3Object.store(path(file), data, bucket_name, options)
        AWS::S3::S3Object.acl(key, bucket_name, policy) unless policy.nil?
      end

      def delete(file)
        connect!
        AWS::S3::S3Object.delete(path(file), bucket_name)
      end

      def to_s
        "s3://#{@config[:access_key_id]}@#{bucket_name}/#{@config[:path]}"
      end

    protected

      def connect!
        options = {
          access_key_id: @config[:access_key_id],
          secret_access_key: @config[:secret_access_key],
          use_ssl: true
        }

        AWS::S3::DEFAULT_HOST.replace(@config[:host]) if @config[:host]
        AWS::S3::Base.establish_connection!(options) unless AWS::S3::Base.connected?
      end

      def bucket_name
        @config[:bucket_name]
      end

      def path(file)
        if @config[:path] and !@config[:path].empty?
          "#{@config[:path]}/#{file}"
        else
          file
        end
      end
    end
  end
end
